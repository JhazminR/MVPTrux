import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Rutas_data.dart';
import '../AppData.dart';

class MapaDetalleRuta extends StatefulWidget {
  final Destino? destinoSeleccionado;
  final int? indiceSubida;
  final int? indiceBajada;
  final bool? esDestinoDirecto;
  final double? distanciaCaminataFinal;
  final bool soloRuta;

  const MapaDetalleRuta({
    super.key,
    this.destinoSeleccionado,
    this.indiceSubida,
    this.indiceBajada,
    this.esDestinoDirecto,
    this.distanciaCaminataFinal,
    this.soloRuta = false,
  });

  @override
  State<MapaDetalleRuta> createState() => _MapaDetalleRutaState();
}

class _MapaDetalleRutaState extends State<MapaDetalleRuta> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  int _etaMinutos = 0;
  double _distanciaKm = 0.0;

  @override
  void initState() {
    super.initState();
    _prepararMapa();
  }

  void _prepararMapa() {
    // Ubicación del usuario (si está disponible)
    final ubicacionUsuario = AppData.currentPosition != null
        ? LatLng(
            AppData.currentPosition!.latitude,
            AppData.currentPosition!.longitude,
          )
        : const LatLng(-8.115, -79.028);

    // Siempre mostrar la polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('ruta_completa'),
        points: RutasData.rutaPrincipal.polyline,
        color: const Color(0xFF0040A1),
        width: 5,
      ),
    );

    // ============================================================
    //  MODO SOLO RUTA
    // ============================================================
    if (widget.soloRuta) {
      // Agregar marcador del usuario si está disponible
      if (AppData.currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('usuario'),
            position: ubicacionUsuario,
            infoWindow: const InfoWindow(title: 'Tú estás aquí'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Calcular distancia total de la ruta
      double distanciaTotal = 0;
      final polyline = RutasData.rutaPrincipal.polyline;
      for (int i = 0; i < polyline.length - 1; i++) {
        distanciaTotal += RutasData.calcularDistanciaMetros(
          polyline[i],
          polyline[i + 1],
        );
      }
      _distanciaKm = distanciaTotal / 1000;
      _etaMinutos = RutasData.calcularETA(distanciaTotal);
      return;
    }

    // ============================================================
    //  MODO DETALLE COMPLETO (con destino, subida, bajada)
    // ============================================================
    // Verificar que tengamos todos los parámetros necesarios
    if (widget.destinoSeleccionado == null ||
        widget.indiceSubida == null ||
        widget.indiceBajada == null) {
      // Fallback: mostrar solo la ruta (sin marcadores extra)
      return;
    }

    final destino = widget.destinoSeleccionado!;
    final indexSubida = widget.indiceSubida!;
    final indexBajada = widget.indiceBajada!;

    // Puntos de la polyline
    final paradaSubida = RutasData.rutaPrincipal.polyline[indexSubida];
    final paradaBajada = RutasData.rutaPrincipal.polyline[indexBajada];

    // Distancias
    final distanciaCaminataInicial = RutasData.calcularDistanciaMetros(
      ubicacionUsuario,
      paradaSubida,
    );
    final distanciaMicro = RutasData.calcularDistanciaRuta(
      indexSubida,
      indexBajada,
    );

    double distanciaCaminataFinal;
    if (widget.esDestinoDirecto ?? false) {
      distanciaCaminataFinal = 0;
    } else {
      distanciaCaminataFinal = RutasData.calcularDistanciaMetros(
        paradaBajada,
        destino.coordenadas,
      );
    }

    // Marcador del usuario
    _markers.add(
      Marker(
        markerId: const MarkerId('usuario'),
        position: ubicacionUsuario,
        infoWindow: const InfoWindow(title: 'Tú estás aquí'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Marcador de subida (naranja)
    _markers.add(
      Marker(
        markerId: const MarkerId('subida'),
        position: paradaSubida,
        infoWindow: InfoWindow(
          title: 'Parada de subida',
          snippet:
              'Camina ${distanciaCaminataInicial.round()} m desde tu ubicación',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    // Marcador de bajada (verde si directo, naranja si hay caminata)
    final esDirecto = widget.esDestinoDirecto ?? false;
    final snippetBajada = esDirecto
        ? 'El micro te deja en tu destino'
        : 'Camina ${distanciaCaminataFinal.round()} m hasta tu destino';

    _markers.add(
      Marker(
        markerId: const MarkerId('bajada'),
        position: paradaBajada,
        infoWindow: InfoWindow(
          title: 'Parada de bajada',
          snippet: snippetBajada,
        ),
        icon: esDirecto
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    // Marcador del destino
    _markers.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: destino.coordenadas,
        infoWindow: InfoWindow(title: destino.nombre),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Calcular ETA total y distancia
    final distanciaTotal =
        distanciaCaminataInicial + distanciaMicro + distanciaCaminataFinal;
    _etaMinutos = RutasData.calcularETA(distanciaTotal);
    _distanciaKm = distanciaTotal / 1000;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Determinar qué puntos usar para ajustar la cámara
    List<LatLng> puntos = [];

    if (widget.soloRuta) {
      // Modo solo ruta: usar toda la polyline
      puntos = RutasData.rutaPrincipal.polyline;
    } else {
      // Modo detalle: usar usuario, subida, bajada, destino
      if (AppData.currentPosition != null) {
        puntos.add(
          LatLng(
            AppData.currentPosition!.latitude,
            AppData.currentPosition!.longitude,
          ),
        );
      }
      if (widget.destinoSeleccionado != null) {
        puntos.add(widget.destinoSeleccionado!.coordenadas);
      }
      if (widget.indiceSubida != null &&
          widget.indiceSubida! < RutasData.rutaPrincipal.polyline.length) {
        puntos.add(RutasData.rutaPrincipal.polyline[widget.indiceSubida!]);
      }
      if (widget.indiceBajada != null &&
          widget.indiceBajada! < RutasData.rutaPrincipal.polyline.length) {
        puntos.add(RutasData.rutaPrincipal.polyline[widget.indiceBajada!]);
      }
      // Si no hay puntos, usar la polyline completa
      if (puntos.isEmpty) {
        puntos = RutasData.rutaPrincipal.polyline;
      }
    }

    // Ajustar cámara a los puntos
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        final bounds = _boundsFromLatLngList(puntos);
        _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } catch (e) {
        // Fallback: si falla, centrar en Trujillo
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(target: LatLng(-8.115, -79.028), zoom: 13),
          ),
        );
      }
    });
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      // Fallback: si la lista está vacía, devolver un bounds por defecto (sin const)
      return LatLngBounds(
        northeast: const LatLng(-8.0, -79.0),
        southwest: const LatLng(-8.2, -79.1),
      );
    }
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
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si estamos en modo solo ruta
    final esSoloRuta = widget.soloRuta;

    // Texto de la tarjeta superior
    String titulo = esSoloRuta ? 'RECORRIDO COMPLETO' : 'RUTA COMBINADA';
    String subtitulo = esSoloRuta
        ? 'Vista completa de la ruta'
        : (widget.esDestinoDirecto ?? false)
        ? 'Llegada en $_etaMinutos min'
        : 'Llegada en $_etaMinutos min (camina ${(widget.distanciaCaminataFinal ?? 0).round()} m)';

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

          // 3. Tarjeta superior de información
          Positioned(
            top: 50,
            left: 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Color(0xFF0040A1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8A8D9F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_distanciaKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007232),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}