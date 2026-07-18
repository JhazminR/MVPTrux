import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trux_mvp/AppData.dart';
import 'package:trux_mvp/Rutas_data.dart';
import 'MapaDetalleRuta.dart';

class PantallaRutas extends StatefulWidget {
  final VoidCallback? onVolverAlMapa;

  const PantallaRutas({super.key, this.onVolverAlMapa});

  @override
  State<PantallaRutas> createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  final List<Destino> _todosLosDestinos = RutasData.getDestinos();
  final List<Destino> _busquedasRecientes = [];
  final TextEditingController _buscadorController = TextEditingController();
  List<Destino> _destinosFiltrados = [];
  List<Map<String, dynamic>> _microsActivos = [];
  StreamSubscription<QuerySnapshot>? _microsSubscription;

  @override
  void initState() {
    super.initState();
    _destinosFiltrados = [];
    _escucharMicros();
  }

  @override
  void dispose() {
    _microsSubscription?.cancel();
    _buscadorController.dispose();
    super.dispose();
  }

  void _escucharMicros() {
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
          });
        });
  }

  void _filtrarDestinos(String query) {
    setState(() {
      if (query.isEmpty) {
        _destinosFiltrados = _todosLosDestinos;
      } else {
        _destinosFiltrados = _todosLosDestinos
            .where(
              (destino) =>
                  destino.nombre.toLowerCase().contains(query.toLowerCase()) ||
                  destino.direccion.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  // 2. Nueva función: Tarjeta Modal en lugar de SnackBar
  void _mostrarTarjetaResultados(BuildContext context, Destino destino) {
    // Guardar en recientes
    setState(() {
      _busquedasRecientes.removeWhere((d) => d.nombre == destino.nombre);
      _busquedasRecientes.insert(0, destino);
      if (_busquedasRecientes.length > 4) _busquedasRecientes.removeLast();
    });

    // 1. Ubicación del usuario
    LatLng ubicacionUsuario = AppData.currentPosition != null
        ? LatLng(
            AppData.currentPosition!.latitude,
            AppData.currentPosition!.longitude,
          )
        : const LatLng(-8.115, -79.028);

    // 2. Índice de subida (más cercano al usuario)
    int indexSubida = RutasData.getNearestIndexOnRoute(ubicacionUsuario);
    LatLng paradaSubida = RutasData.rutaPrincipal.polyline[indexSubida];

    // 3. Índice de bajada (más cercano al destino) - SIN usar puntoIndice
    int indexDestino = RutasData.getNearestIndexOnRoute(destino.coordenadas);
    LatLng paradaBajada = RutasData.rutaPrincipal.polyline[indexDestino];

    // 4. Distancias
    double distanciaCaminataInicial = RutasData.calcularDistanciaMetros(
      ubicacionUsuario,
      paradaSubida,
    );

    double distanciaCaminataFinal = RutasData.calcularDistanciaMetros(
      paradaBajada,
      destino.coordenadas,
    );

    // 5. Determinar si es destino directo (distancia menor a 10 metros)
    bool esDestinoDirecto = distanciaCaminataFinal < 10;
    if (esDestinoDirecto) {
      distanciaCaminataFinal = 0;
    }

    // 6. Distancia en micro (entre subida y bajada)
    double distanciaMicro = RutasData.calcularDistanciaRuta(
      indexSubida,
      indexDestino,
    );

    // 7. ETA total
    double distanciaTotal =
        distanciaCaminataInicial + distanciaMicro + distanciaCaminataFinal;
    int etaMinutos = RutasData.calcularETA(distanciaTotal);

    // 8. Generar instrucciones claras
    String mensajeCaminataInicial = distanciaCaminataInicial > 10
        ? 'Camina ${distanciaCaminataInicial.round()} m hasta la parada'
        : 'Estás cerca de la parada (${distanciaCaminataInicial.round()} m)';

    String mensajeCaminataFinal = (distanciaCaminataFinal < 10)
        ? 'El micro te deja en tu destino'
        : 'Camina ${distanciaCaminataFinal.round()} m hasta tu destino';

    String mensajeRecorrido =
        'Toma el micro Ícaro (Línea D) por ${(distanciaMicro / 1000).toStringAsFixed(1)} km';

    // 9. Mostrar el modal
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        LatLng ubicacionUsuario = AppData.currentPosition != null
            ? LatLng(
                AppData.currentPosition!.latitude,
                AppData.currentPosition!.longitude,
              )
            : const LatLng(-8.115, -79.028);

        // 2. Encontrar el micro más cercano (desde _microsActivos)
        LatLng ubicacionMicro;
        if (_microsActivos.isNotEmpty) {
          // Filtrar micros por ruta 'D' (Ícaro) - ajusta según tu lógica
          final microsRuta = _microsActivos
              .where((m) => m['ruta'] == 'D')
              .toList();
          if (microsRuta.isNotEmpty) {
            // Elegir el más cercano al usuario
            final microCercano = microsRuta.reduce((a, b) {
              double distA = RutasData.calcularDistanciaMetros(
                ubicacionUsuario,
                LatLng(a['lat'], a['lng']),
              );
              double distB = RutasData.calcularDistanciaMetros(
                ubicacionUsuario,
                LatLng(b['lat'], b['lng']),
              );
              return distA < distB ? a : b;
            });
            ubicacionMicro = LatLng(microCercano['lat'], microCercano['lng']);
          } else {
            // Si no hay micros en la ruta 'D', usar el más cercano en general
            final microCercano = _microsActivos.reduce((a, b) {
              double distA = RutasData.calcularDistanciaMetros(
                ubicacionUsuario,
                LatLng(a['lat'], a['lng']),
              );
              double distB = RutasData.calcularDistanciaMetros(
                ubicacionUsuario,
                LatLng(b['lat'], b['lng']),
              );
              return distA < distB ? a : b;
            });
            ubicacionMicro = LatLng(microCercano['lat'], microCercano['lng']);
          }
        } else {
          // Fallback: usar el primer punto de la polyline
          ubicacionMicro = RutasData.rutaPrincipal.polyline.first;
        }
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ruta combinada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1C),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007232).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$etaMinutos min',
                      style: const TextStyle(
                        color: Color(0xFF007232),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Instrucciones paso a paso
              _buildStepItem(
                Icons.directions_walk,
                mensajeCaminataInicial,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                Icons.directions_bus,
                mensajeRecorrido,
                const Color(0xFF0040A1),
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                Icons.directions_walk,
                mensajeCaminataFinal,
                Colors.orange,
              ),

              const SizedBox(height: 24),

              // Mapa en miniatura
              Container(
                height: 150,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: ubicacionUsuario,
                      zoom: 14,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('ruta_miniatura'),
                        points: RutasData.rutaPrincipal.polyline,
                        color: const Color(0xFF0040A1),
                        width: 3,
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('usuario_mini'),
                        position: ubicacionUsuario,
                        infoWindow: const InfoWindow(title: 'Tú'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('subida_mini'),
                        position: paradaSubida,
                        infoWindow: const InfoWindow(title: 'Subida'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('destino_mini'),
                        position: destino.coordenadas,
                        infoWindow: InfoWindow(title: destino.nombre),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('micro_mini'),
                        position: ubicacionMicro,
                        infoWindow: const InfoWindow(title: 'Micro'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                    },
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: false,
                    myLocationEnabled: false,
                  ),
                ),
              ),

              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0040A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaDetalleRuta(
                          destinoSeleccionado: destino,
                          // Pasamos los índices para que el mapa los use
                          indiceSubida: indexSubida,
                          indiceBajada: indexDestino,
                          esDestinoDirecto: esDestinoDirecto,
                          distanciaCaminataFinal: distanciaCaminataFinal,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver detalles en el mapa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget auxiliar para cada paso
  Widget _buildStepItem(IconData icon, String texto, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF1A1C1C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lógica visual: Si no se ha escrito nada y hay recientes, muestra recientes.
    bool mostrandoRecientes =
        _buscadorController.text.isEmpty && _busquedasRecientes.isNotEmpty;
    List<Destino> listaAMostrar = mostrandoRecientes
        ? _busquedasRecientes
        : _destinosFiltrados;

    return Container(
      color: const Color(0xFFF9F9F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(
                bottom: BorderSide(color: Color(0xFFC3C6D6), width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0040A1)),
                  onPressed: () {
                    if (widget.onVolverAlMapa != null) widget.onVolverAlMapa!();
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Planear ruta',
                  style: TextStyle(
                    color: Color(0xFF1A1C1C),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // --- 3. Tarjeta de Inputs Estilo Figma ---
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 16, right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0040A1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: Color(0xFFC3C6D6),
                                    size: 16,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      enabled: false, // Simula "Mi ubicación"
                                      decoration: InputDecoration(
                                        hintText: 'Mi ubicación',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF1A1C1C),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 7),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    height: 12,
                                    child: VerticalDivider(
                                      color: Color(0xFFC3C6D6),
                                      thickness: 1,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Color(0xFF0040A1),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _buscadorController,
                                      onChanged: _filtrarDestinos,
                                      decoration: const InputDecoration(
                                        hintText: '¿Hacia dónde vas?',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF8A8D9F),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón de Intercambio
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F0FF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Color(0xFF0040A1),
                          ),
                          onPressed: () {}, // Simulación visual
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- 4. Chips de Acceso Rápido ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildQuickActionChip(
                          Icons.home,
                          'Casa',
                          isPrimary: true,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(Icons.work_outline, 'Trabajo'),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(Icons.add, 'Guardar'),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Divider(color: Color(0xFFC3C6D6)),
                  ),

                  // --- 5. Lista de Resultados / Recientes ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      _getTituloSeccion(),
                      style: const TextStyle(
                        color: Color(0xFF8A8D9F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // Contenido de la lista
                  if (_debeMostrarMensajeVacio())
                    _buildEmptyStateWidget()
                  else if (listaAMostrar.isEmpty)
                    _buildEmptyResultsWidget()
                  else
                    ...listaAMostrar.map(
                      (destino) => _buildDestinoItem(
                        context,
                        destino,
                        mostrandoRecientes,
                      ),
                    ),

                  // Espacio adicional al final para simular la tarjeta "Trujillo en Movimiento" si hay pocos items
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Determinar si estamos en el estado "sin búsqueda y sin recientes"
  bool _debeMostrarMensajeVacio() {
    return _buscadorController.text.isEmpty && _busquedasRecientes.isEmpty;
  }

  // Obtener el título de la sección
  String _getTituloSeccion() {
    if (_buscadorController.text.isNotEmpty) {
      return 'RESULTADOS';
    } else if (_busquedasRecientes.isNotEmpty) {
      return 'RECIENTES';
    } else {
      return ''; // No hay título cuando está vacío
    }
  }

  // Widget para el estado "sin búsquedas recientes"
  Widget _buildEmptyStateWidget() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Color(0xFFC3C6D6), size: 64),
            SizedBox(height: 16),
            Text(
              'Aún no has realizado búsquedas recientes',
              style: TextStyle(
                color: Color(0xFF8A8D9F),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Busca un destino para comenzar',
              style: TextStyle(color: Color(0xFFB0B3C4), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el estado "sin resultados de búsqueda"
  Widget _buildEmptyResultsWidget() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Text(
          'No se encontraron destinos.',
          style: TextStyle(color: Color(0xFF8A8D9F)),
        ),
      ),
    );
  }

  // Widget para los botones (Casa, Trabajo)
  Widget _buildQuickActionChip(
    IconData icon,
    String label, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF5DFD8A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isPrimary
                ? const Color(0xFF007232)
                : const Color(0xFF424654),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? const Color(0xFF007232)
                  : const Color(0xFF1A1C1C),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Elemento individual de la lista
  Widget _buildDestinoItem(
    BuildContext context,
    Destino destino,
    bool isRecent,
  ) {
    return InkWell(
      onTap: () => _mostrarTarjetaResultados(context, destino),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRecent ? Icons.history : Icons.place,
                color: const Color(0xFF8A8D9F),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destino.nombre,
                    style: const TextStyle(
                      color: Color(0xFF1A1C1C),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destino.direccion,
                    style: const TextStyle(
                      color: Color(0xFF8A8D9F),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west,
              color: Color(0xFF8A8D9F),
              size: 20,
            ), // Flecha diagonal
          ],
        ),
      ),
    );
  }
}
