import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trux_mvp/AppData.dart';
import 'package:trux_mvp/screens/MapaDetalleRuta.dart';
import 'package:trux_mvp/screens/PantallaAlertas.dart';
import 'package:trux_mvp/screens/PantallaPerfil.dart';
import 'package:trux_mvp/screens/PantallaTrofeo.dart';
import 'PantallaRutas.dart';
import 'package:geocoding/geocoding.dart';
import '../Rutas_data.dart'; // 👈 AGREGAR IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class MapaPrincipal extends StatefulWidget {
  final String rol;
  const MapaPrincipal({super.key, this.rol = 'pasajero'});

  @override
  State<MapaPrincipal> createState() => _MapaPrincipalState();
}

class _MapaPrincipalState extends State<MapaPrincipal> {
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Marker? _userMarker;
  Set<Marker> _vehicleMarkers = {};
  StreamSubscription<QuerySnapshot>? _vehiclesSubscription;
  bool _isLocationReady = false;
  bool _isLoading = true;
  final ValueNotifier<Map<String, Map<String, dynamic>>> _microDataNotifier =
      ValueNotifier({});
  Map<String, Map<String, dynamic>> _microData = {};
  int _selectedIndex = 0;
  Set<Polyline> _rutasPolylines = {};
  // Variables para almacenar los iconos ya procesados
  BitmapDescriptor? _iconoBC;
  BitmapDescriptor? _iconoD;

  // Función para redimensionar imágenes y convertirlas en marcadores
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // Carga inicial de los assets
  Future<void> _cargarIconosPersonalizados() async {
    // Redimensionamos de 400x400 a 100px para que se vean proporcionados en el mapa
    final Uint8List markerIconBC = await _getBytesFromAsset(
      'assets/images/icono_bc.png',
      100,
    );
    final Uint8List markerIconD = await _getBytesFromAsset(
      'assets/images/icono_d.png',
      100,
    );

    if (mounted) {
      setState(() {
        _iconoBC = BitmapDescriptor.fromBytes(markerIconBC);
        _iconoD = BitmapDescriptor.fromBytes(markerIconD);
      });
    }
  }

  static const LatLng _initialPosition = LatLng(-8.115, -79.028);

  void _cargarPolyline() {
    setState(() {
      _rutasPolylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_principal_icaro'),
          points: RutasData.rutaPrincipal.polyline, // Extrae los 357 puntos
          color: const Color(0xFFE53935), // Color rojo para que resalte
          width: 5, // Grosor de la línea
          geodesic: true,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarIconosPersonalizados();
    //_cargarPolyline();
    if (AppData.currentPosition != null) {
      setState(() {
        _currentPosition = AppData.currentPosition;
        _isLoading = false;
        _isLocationReady = true;
      });
      _listenToVehicles();
    } else {
      _getCurrentLocation();
    }
    _startListeningToLocationChanges();
    _listenToVehicles();
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // --- UBICACIÓN DEL USUARIO ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso bloqueado permanentemente. Ve a ajustes.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLocationReady = true;
        _isLoading = false;
        _updateUserMarker(position);
      });
      _moveCameraToUser(position);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _startListeningToLocationChanges() {
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.denied) {
        Geolocator.requestPermission();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        print('Permiso denegado permanentemente');
        return;
      }

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 2,
            ),
          ).listen((Position position) {
            setState(() {
              _currentPosition = position;
              _updateUserMarker(position);
            });
          });
    });
  }

  // --- Movimiento de cámara ---
  void _moveCameraToUser(Position position, {bool preserveZoom = true}) {
    if (_mapController == null) return;

    if (preserveZoom) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 16,
          ),
        ),
      );
    }
  }

  void _updateUserMarker(Position position) {
    _userMarker = Marker(
      markerId: const MarkerId('user_marker'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Tu ubicación'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  // --- MÓDULO DE SEGURIDAD (HIPÓTESIS 2) ---
  Future<void> _enviarAlertaWhatsApp() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún obteniendo tu ubicación...')),
      );
      return;
    }

    // Capturamos las coordenadas actuales
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final urlMaps = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    // Como es un MVP, podemos simular la variable de la línea o tomar la más cercana.
    // Aquí predefinimos el mensaje base requerido para la validación del jurado.
    final String mensaje =
        "🚨 *Alerta Trux* 🚨\n\n"
        "Estoy viajando en la Línea D (Micro Ícaro). Mi ubicación en vivo es:\n"
        "$urlMaps\n\n"
        "Llegaré a mi destino en aproximadamente 15 minutos.";

    // Codificamos el mensaje para que sea válido en una URL
    final String mensajeCodificado = Uri.encodeComponent(mensaje);
    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?text=$mensajeCodificado",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication, // 👈 SOLUCIÓN AGREGADA AQUÍ
        );
      } else {
        // Fallback por si no tienen WhatsApp instalado o están en emulador
        final Uri webUrl = Uri.parse("https://wa.me/?text=$mensajeCodificado");
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'No se pudo abrir WhatsApp ni el navegador web.';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir WhatsApp. Verifica que esté instalado.',
            ),
          ),
        );
      }
    }
  }

  // --- Cálculo de distancia ---
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double R = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);
    double a =
        _haversin(dLat) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            _haversin(dLng);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * Math.pi / 180.0;
  num _haversin(double theta) => Math.pow(Math.sin(theta / 2), 2);

  // --- VEHÍCULOS ---
  void _listenToVehicles() {
    _vehiclesSubscription = FirebaseFirestore.instance
        .collection('unidades')
        .where('estado', isEqualTo: 'en_ruta')
        .snapshots()
        .listen(
          (snapshot) {
            Set<Marker> newMarkers = {};
            final now = DateTime.now();
            Map<String, Map<String, dynamic>> newMicroData = {};

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final lat = data['latitud'] as double?;
              final lng = data['longitud'] as double?;
              final ruta = data['ruta'] as String? ?? 'A';
              final ultimaActualizacion =
                  (data['ultima_actualizacion'] as Timestamp?)?.toDate();

              if (ultimaActualizacion == null) continue;
              final diff = now.difference(ultimaActualizacion);
              if (diff.inSeconds > 15) {
                print('🚫 Vehículo ${doc.id} inactivo (${diff.inSeconds}s)');
                continue;
              }

              if (lat != null && lng != null) {
                newMicroData[doc.id] = {
                  'ruta': ruta,
                  'lat': lat,
                  'lng': lng,
                  'ultimaActualizacion': ultimaActualizacion,
                };

                // Lógica condicional para asignar el icono según la ruta
                BitmapDescriptor iconoVehiculo =
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    );

                String rutaUpper = ruta.toUpperCase();
                if (rutaUpper == 'D' && _iconoD != null) {
                  iconoVehiculo = _iconoD!;
                } else if ((rutaUpper == 'B' || rutaUpper == 'C') &&
                    _iconoBC != null) {
                  iconoVehiculo = _iconoBC!;
                }

                newMarkers.add(
                  Marker(
                    markerId: MarkerId(doc.id),
                    position: LatLng(lat, lng),
                    icon: iconoVehiculo, // 👈 Se asigna el PNG personalizado
                    // Opcional: Centrar el punto de anclaje de la imagen
                    anchor: const Offset(0.5, 0.5),
                    onTap: () {
                      _showMicroBottomSheet(doc.id);
                    },
                  ),
                );
              }
            }

            setState(() {
              _vehicleMarkers = newMarkers;
              _microData = newMicroData;
              _microDataNotifier.value = newMicroData;
            });
          },
          onError: (error) {
            print('❌ Error escuchando vehículos: $error');
          },
        );
  }

  // --- MODAL DEL MICRO ---
  void _showMicroBottomSheet(String markerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
          valueListenable: _microDataNotifier,
          builder: (context, microData, child) {
            // Obtener datos actualizados del vehículo
            final vehicleData = microData[markerId];
            if (vehicleData == null) {
              // Si el vehículo ya no existe (se detuvo), mostramos un mensaje y cerramos el modal
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El vehículo ya no está disponible.'),
                  ),
                );
              });
              return const SizedBox.shrink();
            }

            // Extraer datos actualizados
            final ruta = vehicleData['ruta'] ?? 'A';
            final lat = vehicleData['lat'] as double;
            final lng = vehicleData['lng'] as double;
            final ultimaActualizacion =
                vehicleData['ultimaActualizacion'] as DateTime?;

            // Calcular distancia y ETA con los datos actuales
            double? distanciaKm;
            if (_currentPosition != null) {
              distanciaKm = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lng,
              );
            }

            String etaText = 'N/A';
            if (distanciaKm != null) {
              double velocidadKmh = 20;
              double tiempoHoras = distanciaKm / velocidadKmh;
              int minutos = (tiempoHoras * 60).round();
              if (minutos < 1) {
                etaText = 'Menos de 1 min';
              } else if (minutos < 60) {
                etaText = '$minutos min';
              } else {
                int horas = minutos ~/ 60;
                int mins = minutos % 60;
                etaText = '$horas h ${mins} min';
              }
            }

            // Formatear última actualización
            String tiempoActualizacion = 'Desconocido';
            if (ultimaActualizacion != null) {
              final diff = DateTime.now().difference(ultimaActualizacion);
              if (diff.inSeconds < 60) {
                tiempoActualizacion = 'Hace ${diff.inSeconds} seg';
              } else if (diff.inMinutes < 60) {
                tiempoActualizacion = 'Hace ${diff.inMinutes} min';
              } else if (diff.inHours < 24) {
                tiempoActualizacion = 'Hace ${diff.inHours} h';
              } else {
                tiempoActualizacion = 'Hace ${diff.inDays} días';
              }
            }

            // Obtener dirección (con caché para evitar llamadas repetidas)
            return FutureBuilder<String>(
              future: _getAddressWithCache(lat, lng),
              builder: (context, snapshot) {
                final ubicacion = snapshot.data ?? 'Cargando dirección...';
                return _buildBottomSheetContent(
                  ruta: ruta,
                  ubicacion: ubicacion,
                  distanciaKm: distanciaKm,
                  etaText: etaText,
                  tiempoActualizacion: tiempoActualizacion,
                  ultimaActualizacion: ultimaActualizacion,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _getAddressWithFallback(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        lat,
        lng,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String> parts = [];
        if (place.street != null && place.street!.isNotEmpty)
          parts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          parts.add(place.locality!);
        if (parts.isNotEmpty) {
          return parts.join(', ');
        } else {
          return place.country ?? 'Ubicación desconocida';
        }
      } else {
        return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }
  }

  // Variables de caché para geocodificación
  String? _cachedAddress;
  double? _cachedLat;
  double? _cachedLng;

  Future<String> _getAddressWithCache(double lat, double lng) async {
    // Si la distancia desde la última consulta es menor a 50 metros, usar caché
    if (_cachedLat != null && _cachedLng != null) {
      double dist =
          _calculateDistance(_cachedLat!, _cachedLng!, lat, lng) * 1000;
      if (dist < 50 && _cachedAddress != null) {
        return _cachedAddress!;
      }
    }

    // Obtener nueva dirección
    String address = await _getAddressWithFallback(lat, lng);
    _cachedAddress = address;
    _cachedLat = lat;
    _cachedLng = lng;
    return address;
  }

  // --- Widgets del bottom sheet (AHORA DENTRO DE LA CLASE) ---
  // --- UI DEL BOTTOM SHEET (ACTUALIZADA CON ETA Y ESTADO) ---
  Widget _buildBottomSheetContent({
    required String ruta,
    required String ubicacion,
    double? distanciaKm,
    required String etaText,
    required String tiempoActualizacion,
    DateTime? ultimaActualizacion, // 👈 Recibimos la fecha exacta
  }) {
    String distanciaText = 'N/A';
    if (distanciaKm != null) {
      if (distanciaKm < 1) {
        distanciaText = '${(distanciaKm * 1000).round()} m';
      } else {
        distanciaText = '${distanciaKm.toStringAsFixed(1)} km';
      }
    }

    // --- LÓGICA DE ESTADO (MÓDULO 4) ---
    int segundosDesdeActualizacion = 0;
    if (ultimaActualizacion != null) {
      segundosDesdeActualizacion = DateTime.now()
          .difference(ultimaActualizacion)
          .inSeconds;
    }
    bool enCamino = segundosDesdeActualizacion <= 15;

    Color estadoColor = enCamino
        ? const Color(0xFF007232)
        : const Color(0xFFE53935);
    Color fondoEstadoColor = enCamino
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    String estadoTexto = enCamino ? "En camino" : "Detenido";
    IconData estadoIcono = enCamino ? Icons.sensors : Icons.sensors_off;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Color(0xFF0040A1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Micro - Línea $ruta',
                      style: const TextStyle(
                        color: Color(0xFF0040A1),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      ubicacion,
                      style: const TextStyle(
                        color: Color(0xFF424654),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- 1. CHIP DE ESTADO DE CONEXIÓN ---
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: fondoEstadoColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(estadoIcono, color: estadoColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    estadoTexto,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tiempoActualizacion, // Muestra "Hace X seg"
                    style: TextStyle(
                      color: estadoColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. VISIBILIDAD DE ETA Y DISTANCIA GIGANTE ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiempo estimado',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etaText, // Ej: "15 min"
                      style: const TextStyle(
                        fontSize: 24, // Tamaño grande para fácil lectura
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: const Color(0xFFE0E0E0), // Divisor
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Distancia',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      distanciaText, // Ej: "2.4 km"
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0040A1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // BOTÓN 1: VER DETALLE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapaDetalleRuta(soloRuta: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0040A1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver detalle de ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // BOTÓN 2: REPORTAR AFORO
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogAforo(ruta);
              },
              icon: const Icon(Icons.campaign, color: Color(0xFF0040A1)),
              label: const Text(
                'Reportar aforo',
                style: TextStyle(
                  color: Color(0xFF0040A1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF0040A1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0040A1), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF737785),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A1C1C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // --- MÓDULO DE AFORO / GAMIFICACIÓN (HIPÓTESIS 2 - CROWDSOURCING) ---
  void _mostrarDialogAforo(String ruta) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '¿Cómo va el micro?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1C),
              fontFamily: 'Inter',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ayuda a otros pasajeros reportando el aforo de este vehículo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF424654), fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildAforoOption(
                icon: Icons.event_seat,
                color: const Color(0xFF007232), // Verde
                label: 'Vacío (Hay asientos)',
                onTap: () => _enviarReporteAforo(ruta, 'vacio'),
              ),
              const Divider(height: 1),
              _buildAforoOption(
                icon: Icons.people,
                color: const Color(0xFFF57C00), // Naranja
                label: 'Medio (Gente parada)',
                onTap: () => _enviarReporteAforo(ruta, 'medio'),
              ),
              const Divider(height: 1),
              _buildAforoOption(
                icon: Icons.groups,
                color: const Color(0xFFE53935), // Rojo
                label: 'Lleno (No entra nadie)',
                onTap: () => _enviarReporteAforo(ruta, 'lleno'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAforoOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _enviarReporteAforo(String ruta, String nivel) async {
    Navigator.pop(context); // Cierra el dialog

    try {
      // Escritura rápida en Firestore (Dummy para validar interacción)
      await FirebaseFirestore.instance.collection('reportes_aforo').add({
        'ruta': ruta,
        'nivel_aforo': nivel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Feedback visual inmediato y gamificación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Gracias por reportar! Ganaste 10 puntos en Trux.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0040A1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error guardando reporte: $e');
    }
  }

  // --- UI PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapScreen(), // Índice 0: Mapa
          PantallaRutas(
            // Índice 1 (¡Modificamos esto!)
            onVolverAlMapa: () {
              setState(() {
                _selectedIndex = 0; // Cambia a la pestaña del mapa
              });
            },
          ),
          const PantallaAlertas(), // Índice 2: Alertas
          const PantallaTrofeo(), // Índice 3: Trofeo
          const PantallaPerfil(), // Índice 4: Perfil
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMapScreen() {
    return Stack(
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _initialPosition,
              zoom: 16,
            ),
            polylines: _rutasPolylines,
            markers: {
              if (_userMarker != null) _userMarker!,
              ..._vehicleMarkers,
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
        Positioned(
          bottom: 120,
          right: 16,
          child: Column(
            children: [
              // 🔴 NUEVO BOTÓN DE SEGURIDAD
              FloatingActionButton(
                heroTag: 'btn_seguridad',
                mini:
                    false, // Más grande para que sea fácil de presionar en pánico
                backgroundColor: const Color(0xFFE53935), // Rojo alerta
                onPressed: _enviarAlertaWhatsApp,
                child: const Icon(Icons.shield, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16), // Espaciado mayor
              FloatingActionButton(
                heroTag: 'btn_ubicacion',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Obteniendo ubicación...')),
                    );
                  }
                },
                child: const Icon(Icons.my_location, color: Color(0xFF0040A1)),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'btn_zoom_mas',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                },
                child: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'btn_zoom_menos',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                },
                child: const Icon(Icons.remove, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: const Border(
          top: BorderSide(color: Color(0xFFC3C6D6), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.map, label: 'Mapa', index: 0),
          _buildNavItem(icon: Icons.route, label: 'Rutas', index: 1),
          _buildNavItem(icon: Icons.notifications, label: 'Alertas', index: 2),
          _buildNavItem(icon: Icons.emoji_events, label: 'Trofeo', index: 3),
          _buildNavItem(icon: Icons.person, label: 'Perfil', index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedIndex == index;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF5DFD8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF007232)
                    : const Color(0xFF424654),
                size: 22,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF007232)
                        : const Color(0xFF424654),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
