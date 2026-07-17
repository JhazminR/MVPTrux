import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trux_mvp/AppData.dart';
import 'package:trux_mvp/screens/PantallaAlertas.dart';
import 'package:trux_mvp/screens/PantallaPerfil.dart';
import 'package:trux_mvp/screens/PantallaTrofeo.dart';
import 'PantallaRutas.dart';
import 'package:geocoding/geocoding.dart'; // 👈 AGREGAR IMPORT

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

  static const LatLng _initialPosition = LatLng(-8.115, -79.028);

  @override
  void initState() {
    super.initState();
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
                newMarkers.add(
                  Marker(
                    markerId: MarkerId(doc.id),
                    position: LatLng(lat, lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
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
  Widget _buildBottomSheetContent({
    required String ruta,
    required String ubicacion,
    double? distanciaKm,
    required String etaText,
    required String tiempoActualizacion,
  }) {
    String distanciaText = 'N/A';
    if (distanciaKm != null) {
      if (distanciaKm < 1) {
        distanciaText = '${(distanciaKm * 1000).round()} m';
      } else {
        distanciaText = '${distanciaKm.toStringAsFixed(1)} km';
      }
    }

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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.straighten,
                  label: 'Distancia',
                  value: distanciaText,
                ),
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: etaText,
                ),
                _buildInfoItem(
                  icon: Icons.update,
                  label: 'Actualizado',
                  value: tiempoActualizacion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Siguiendo unidad de la ruta $ruta...'),
                    backgroundColor: const Color(0xFF0040A1),
                  ),
                );
                // TODO: Navegar a la pestaña Rutas
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0040A1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Seguir unidad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
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

  // --- UI PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapScreen(), // Índice 0: Mapa
          const PantallaRutas(), // Índice 1: Rutas
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(top: BorderSide(color: Color(0xFFC3C6D6), width: 1)),
        boxShadow: [
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
