import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Rutas_data.dart';
import '../AppData.dart';
import '../services/notification_service.dart';

class PantallaAlertas extends StatefulWidget {
  const PantallaAlertas({super.key});

  @override
  State<PantallaAlertas> createState() => _PantallaAlertasState();
}

class _PantallaAlertasState extends State<PantallaAlertas> {
  // Variables de estado
  List<Map<String, dynamic>> _alertas = [];
  List<Map<String, dynamic>> _microsActivos = [];
  bool _isLoading = true;

  // Streams
  StreamSubscription<QuerySnapshot>? _alertasSubscription;
  StreamSubscription<QuerySnapshot>? _microsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMicros();
    _listenToAlertas();
  }

  @override
  void dispose() {
    _alertasSubscription?.cancel();
    _microsSubscription?.cancel();
    super.dispose();
  }

  // NOTE: removed deviceId logic for emulator testing. Alerts are stored without deviceId.

  // --- Escuchar micros activos en tiempo real ---
  void _listenToMicros() {
    _microsSubscription = FirebaseFirestore.instance
        .collection('unidades')
        .where('estado', isEqualTo: 'en_ruta')
        .snapshots()
        .listen((snapshot) {
          List<Map<String, dynamic>> micros = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final lat = data['latitud'] as double?;
            final lng = data['longitud'] as double?;
            final ruta = data['ruta'] as String? ?? 'A';
            final ultimaActualizacion =
                (data['ultima_actualizacion'] as Timestamp?)?.toDate();
            if (lat != null && lng != null && ultimaActualizacion != null) {
              final diff = DateTime.now().difference(ultimaActualizacion);
              if (diff.inSeconds <= 15) {
                micros.add({
                  'id': doc.id,
                  'lat': lat,
                  'lng': lng,
                  'ruta': ruta,
                  'ultimaActualizacion': ultimaActualizacion,
                });
              }
            }
          }
          setState(() {
            _microsActivos = micros;
            _evaluarAlertas(); // Evaluar alertas con nuevos micros
          });
        });
  }

  // --- Escuchar alertas del usuario desde Firestore ---
  void _listenToAlertas() {
    // Cancelar cualquier suscripción previa antes de crear una nueva
    _alertasSubscription?.cancel();

    // Escuchar todas las alertas (sin filtrar por deviceId) para facilitar pruebas en emulador.
    _alertasSubscription = FirebaseFirestore.instance
        .collection('alertas')
        .snapshots()
        .listen((snapshot) {
          List<Map<String, dynamic>> alertas = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            alertas.add(data);
          }
          setState(() {
            _alertas = alertas;
            _isLoading = false;
          });
          _evaluarAlertas(); // Evaluar alertas después de cargar
        });
  }

  // --- Evaluar si alguna alerta debe dispararse ---
  void _evaluarAlertas() {
    for (var alerta in _alertas) {
      if (!alerta['activo']) continue;

      final rutaMicro = alerta['microRuta'];
      final destinoLat = alerta['destinoCoordenadas']['lat'] as double;
      final destinoLng = alerta['destinoCoordenadas']['lng'] as double;
      final distanciaUmbral = alerta['distanciaMetros'] as double;

      // Buscar micros activos en esa ruta
      final microsRuta = _microsActivos
          .where((m) => m['ruta'] == rutaMicro)
          .toList();
      if (microsRuta.isEmpty) continue;

      // Tomar el más cercano al destino (o el primero)
      final microCercano = microsRuta.reduce((a, b) {
        double distA = RutasData.calcularDistanciaMetros(
          LatLng(a['lat'], a['lng']),
          LatLng(destinoLat, destinoLng),
        );
        double distB = RutasData.calcularDistanciaMetros(
          LatLng(b['lat'], b['lng']),
          LatLng(destinoLat, destinoLng),
        );
        return distA < distB ? a : b;
      });

      final distanciaActual = RutasData.calcularDistanciaMetros(
        LatLng(microCercano['lat'], microCercano['lng']),
        LatLng(destinoLat, destinoLng),
      );

      // Si está dentro del rango y no se ha notificado recientemente
      if (distanciaActual <= distanciaUmbral) {
        final ultimaNotificacion = alerta['ultimaNotificacion'] as Timestamp?;
        if (ultimaNotificacion == null ||
            DateTime.now().difference(ultimaNotificacion.toDate()).inMinutes >
                5) {
          _dispararAlerta(alerta, distanciaActual);
          // Actualizar timestamp para evitar spam
          FirebaseFirestore.instance
              .collection('alertas')
              .doc(alerta['id'])
              .update({'ultimaNotificacion': FieldValue.serverTimestamp()});
        }
      }
    }
  }

  // --- Disparar notificación local ---
  void _dispararAlerta(Map<String, dynamic> alerta, double distanciaMetros) {
    final destinoNombre = alerta['destinoNombre'] ?? 'destino';
    final cuadras = (distanciaMetros / 100).round();
    final mensaje =
        'El micro Ícaro (Línea D) está a $cuadras cuadras de $destinoNombre.';

    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '¡Tu micro se acerca! 🚌',
      body: mensaje,
    );

    // También puedes mostrar un SnackBar si la app está abierta
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: const Color(0xFF0040A1),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // --- Agregar o editar alerta ---
  Future<void> _mostrarDialogAlerta({
    Map<String, dynamic>? alertaExistente,
  }) async {
    final bool esEdicion = alertaExistente != null;

    // Controladores y valores iniciales
    final nombreController = TextEditingController(
      text: esEdicion ? alertaExistente['destinoNombre'] : '',
    );
    double distanciaCuadras = esEdicion
        ? (alertaExistente['distanciaMetros'] / 100).roundToDouble()
        : 3.0;
    String microRuta = esEdicion ? alertaExistente['microRuta'] : 'D';
    bool activo = esEdicion ? alertaExistente['activo'] : true;
    LatLng? destinoCoordenadas;
    if (esEdicion) {
      destinoCoordenadas = LatLng(
        alertaExistente['destinoCoordenadas']['lat'],
        alertaExistente['destinoCoordenadas']['lng'],
      );
    }

    // Lista de destinos para autocompletar
    final destinos = RutasData.getDestinos();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(esEdicion ? 'Editar alerta' : 'Nueva alerta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Micro (solo lectura por ahora)
                    DropdownButtonFormField<String>(
                      value: microRuta,
                      items: const [
                        DropdownMenuItem(
                          value: 'D',
                          child: Text('Ícaro - Línea D'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => microRuta = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Micro'),
                    ),
                    const SizedBox(height: 16),
                    // Destino (búsqueda o selección)
                    Autocomplete<Destino>(
                      displayStringForOption: (Destino d) => d.nombre,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          // Mostrar todos los destinos si el usuario no escribe
                          return destinos;
                        }
                        return destinos.where(
                          (destino) =>
                              destino.nombre.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ) ||
                              destino.direccion.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                        );
                      },
                      onSelected: (destino) {
                        destinoCoordenadas = destino.coordenadas;
                        // actualizar ambos controladores para reflejar la selección
                        nombreController.text = destino.nombre;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            // Usar el controller interno para que Autocomplete funcione
                            // y mantener sincronizado el nombreController para validación
                            controller.addListener(() {
                              if (controller.text != nombreController.text) {
                                nombreController.text = controller.text;
                              }
                            });

                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (value) {
                                if (value.isEmpty) destinoCoordenadas = null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Buscar destino',
                                hintText: 'Ej: Mall Plaza Trujillo',
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 16),
                    // Distancia (slider)
                    Row(
                      children: [
                        const Text('Cuadras: '),
                        Expanded(
                          child: Slider(
                            value: distanciaCuadras,
                            min: 1,
                            max: 15,
                            divisions: 14,
                            label: '${distanciaCuadras.round()} cuadras',
                            onChanged: (value) {
                              setStateDialog(() {
                                distanciaCuadras = value;
                              });
                            },
                          ),
                        ),
                        Text('${distanciaCuadras.round()}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Activo/Inactivo (solo para edición)
                    if (esEdicion)
                      SwitchListTile(
                        title: const Text('Activa'),
                        value: activo,
                        onChanged: (value) {
                          setStateDialog(() => activo = value);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Si el usuario escribió el nombre pero no seleccionó la opción,
                    // intentar resolver el destino por nombre exacto (case-insensitive).
                    if (destinoCoordenadas == null &&
                        nombreController.text.trim().isNotEmpty) {
                      try {
                        final match = destinos.firstWhere(
                          (d) =>
                              d.nombre.toLowerCase() ==
                              nombreController.text.trim().toLowerCase(),
                        );
                        destinoCoordenadas = match.coordenadas;
                      } catch (e) {
                        // no encontrado, dejamos destinoCoordenadas como null
                      }
                    }

                    // 1. Verificar que destinoCoordenadas NO sea nulo y que el nombre no esté vacío
                    if (destinoCoordenadas == null ||
                        nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona un destino válido.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // Salir del onPressed
                    }

                    // 2. Ahora estamos SEGUROS de que destinoCoordenadas no es nulo.
                    //    Creamos variables locales finales para usar en el mapa.
                    final lat = destinoCoordenadas!.latitude;
                    final lng = destinoCoordenadas!.longitude;

                    final data = {
                      'microRuta': microRuta,
                      'destinoNombre': nombreController.text.trim(),
                      'destinoCoordenadas': {'lat': lat, 'lng': lng},
                      'distanciaMetros': distanciaCuadras * 100,
                      'activo': activo,
                    };

                    // 3. Guardar en Firestore
                    if (esEdicion) {
                      FirebaseFirestore.instance
                          .collection('alertas')
                          .doc(alertaExistente['id'])
                          .update(data)
                          .then((_) => Navigator.pop(context));
                    } else {
                      FirebaseFirestore.instance
                          .collection('alertas')
                          .add(data)
                          .then((_) => Navigator.pop(context));
                    }
                  },
                  child: Text(esEdicion ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Eliminar alerta ---
  void _eliminarAlerta(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar alerta'),
        content: const Text('¿Seguro que quieres eliminar esta alerta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('alertas')
                  .doc(id)
                  .delete()
                  .then((_) => Navigator.pop(context));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        title: const Text(
          'Alertas',
          style: TextStyle(
            color: Color(0xFF1A1C1C),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFC3C6D6), height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogAlerta,
        backgroundColor: const Color(0xFF0040A1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alertas.isEmpty
            ? _buildEmptyState()
            : _buildAlertasList(),
      );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Color(0xFFC3C6D6)),
          SizedBox(height: 16),
          Text(
            'No tienes alertas configuradas',
            style: TextStyle(
              color: Color(0xFF8A8D9F),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toca el botón + para crear una',
            style: TextStyle(color: Color(0xFFB0B3C4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _alertas.length,
      itemBuilder: (context, index) {
        final alerta = _alertas[index];
        final distanciaCuadras = (alerta['distanciaMetros'] / 100).round();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono según micro (por ahora fijo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F0FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Color(0xFF0040A1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ícaro - Línea D',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1A1C1C),
                            ),
                          ),
                          Text(
                            alerta['destinoNombre'] ?? 'Destino',
                            style: const TextStyle(
                              color: Color(0xFF424654),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Switch activar/desactivar
                    Switch(
                      value: alerta['activo'] ?? true,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('alertas')
                            .doc(alerta['id'])
                            .update({'activo': value});
                      },
                      activeColor: const Color(0xFF0040A1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: const Color(0xFF8A8D9F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$distanciaCuadras cuadras antes',
                      style: const TextStyle(
                        color: Color(0xFF8A8D9F),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Color(0xFF8A8D9F),
                      ),
                      onPressed: () =>
                          _mostrarDialogAlerta(alertaExistente: alerta),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _eliminarAlerta(alerta['id']),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
