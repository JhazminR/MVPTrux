import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Rutas_data.dart';
import '../AppData.dart';

class MapaDetalleRuta extends StatefulWidget {
  final Destino destinoSeleccionado;

  const MapaDetalleRuta({super.key, required this.destinoSeleccionado});

  @override
  State<MapaDetalleRuta> createState() => _MapaDetalleRutaState();
}

class _MapaDetalleRutaState extends State<MapaDetalleRuta> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // Ubicación mock del Ícaro para el MVP
  final LatLng _ubicacionIcaroMock = const LatLng(-8.112, -79.030);
  int _etaMinutos = 0;
  double _distanciaKm = 0.0;

  @override
  void initState() {
    super.initState();
    _prepararMapa();
  }

  void _prepararMapa() {
    LatLng ubicacionUsuario = AppData.currentPosition != null
        ? LatLng(AppData.currentPosition!.latitude, AppData.currentPosition!.longitude)
        : const LatLng(-8.115, -79.028);

    // Cálculos
    double distanciaMetros = RutasData.calcularDistanciaMetros(ubicacionUsuario, _ubicacionIcaroMock);
    _etaMinutos = RutasData.calcularETA(distanciaMetros);
    _distanciaKm = distanciaMetros / 1000;

    // Configurar Polyline (Línea de la ruta)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('ruta_icaro'),
        points: RutasData.rutaPrincipal.polyline,
        color: const Color(0xFF0040A1), // Azul institucional
        width: 5,
      ),
    );

    // Configurar Marcadores
    _markers.add(
      Marker(
        markerId: const MarkerId('usuario'),
        position: ubicacionUsuario,
        infoWindow: const InfoWindow(title: 'Tú estás aquí'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: widget.destinoSeleccionado.coordenadas,
        infoWindow: InfoWindow(title: widget.destinoSeleccionado.nombre),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('bus_icaro'),
        position: _ubicacionIcaroMock,
        infoWindow: const InfoWindow(title: 'Micro Ícaro'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Ajustar la cámara para que se vea el usuario y el destino
    LatLngBounds bounds = _boundsFromLatLngList([
      if (AppData.currentPosition != null)
        LatLng(AppData.currentPosition!.latitude, AppData.currentPosition!.longitude)
      else
        const LatLng(-8.115, -79.028),
      widget.destinoSeleccionado.coordenadas,
      _ubicacionIcaroMock,
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    });
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. El Mapa
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-8.115, -79.028),
              zoom: 14.0,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Botón de regreso
          Positioned(
            top: 50,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1C)),
              ),
            ),
          ),

          // 3. Tarjeta superior de información de llegada
          Positioned(
            top: 50,
            left: 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Color(0xFF0040A1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRÓXIMO BUS', style: TextStyle(fontSize: 10, color: Color(0xFF8A8D9F), fontWeight: FontWeight.bold)),
                        Text('Llegará en $_etaMinutos min', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
                      ],
                    ),
                  ),
                  Text('${_distanciaKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007232))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}