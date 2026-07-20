import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trux_mvp/AppData.dart';

class ModoConductorSatelite extends StatefulWidget {
  const ModoConductorSatelite({super.key});

  @override
  State<ModoConductorSatelite> createState() => _ModoConductorSateliteState();
}

class _ModoConductorSateliteState extends State<ModoConductorSatelite> {
  // Variables de estado
  bool _isTransmitting = false;
  String? _documentId;
  Timer? _updateTimer;
  Position? _currentPosition;
  bool _isLocationReady = false;
  bool _isLoading = true;

  // Stream para escuchar cambios de ubicación en tiempo real
  StreamSubscription<Position>? _positionStreamSubscription;

  // Controladores y variables para la UI
  final String _unidadInfo = 'MICROBUS ÍCARO - LETRA D';
  final String _appVersion = 'v4.1.0 | TRUX APP';

  // Latencia simulada (en ms)
  int _latency = 0;

  @override
  void initState() {
    super.initState();
    // Si ya tenemos ubicación del Splash, la usamos
    if (AppData.currentPosition != null) {
      _currentPosition = AppData.currentPosition;
      _isLocationReady = true;
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
    _startListeningToLocationChanges(); // 👈 NUEVO: escuchar cambios de ubicación
    _simulateLatency();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _latencyTimer?.cancel();
    _positionStreamSubscription?.cancel(); // 👈 Cancelar listener
    super.dispose();
  }

  // --- Lógica de ubicación y permisos (mejorada) ---

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso bloqueado permanentemente.')),
      );
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
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  // 👇 NUEVO: Escuchar cambios de ubicación en tiempo real
  void _startListeningToLocationChanges() {
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 2, // Actualiza si te mueves más de 2 metros
            ),
          ).listen((Position position) {
            setState(() {
              _currentPosition = position;
            });
            // Si estamos transmitiendo, actualizamos Firestore inmediatamente
            // (esto es opcional porque ya tenemos el timer de 3s, pero ayuda a que sea más preciso)
            if (_isTransmitting && _documentId != null) {
              _updateFirestoreLocation(position);
            }
          });
    });
  }

  // 👇 NUEVO: Actualizar Firestore con la nueva ubicación (sin esperar el timer)
  Future<void> _updateFirestoreLocation(Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('unidades')
          .doc(_documentId)
          .update({
            'latitud': position.latitude,
            'longitud': position.longitude,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
      print('🔄 Ubicación actualizada en tiempo real');
    } catch (e) {
      print('❌ Error actualizando ubicación en tiempo real: $e');
    }
  }

  // --- Lógica de transmisión a Firestore (sin cambios importantes) ---

  void _toggleTransmission() async {
    if (_isTransmitting) {
      await _stopTransmission();
    } else {
      await _startTransmission();
    }
  }

  Future<void> _startTransmission() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Esperando ubicación...')));
      return;
    }

    setState(() => _isTransmitting = true);

    try {
      // Buscar si ya existe un documento para este conductor
      final querySnapshot = await FirebaseFirestore.instance
          .collection('unidades')
          .where(
            'conductorId',
            isEqualTo: 'conductor_${DateTime.now().millisecondsSinceEpoch}',
          )
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _documentId = doc.id;
        await doc.reference.update({
          'latitud': _currentPosition!.latitude,
          'longitud': _currentPosition!.longitude,
          'estado': 'en_ruta',
          'ultima_actualizacion': FieldValue.serverTimestamp(),
        });
        print('🔄 Documento existente actualizado: $_documentId');
      } else {
        final docRef = FirebaseFirestore.instance.collection('unidades').doc();
        _documentId = docRef.id;
        await docRef.set({
          'conductorId': 'conductor_${DateTime.now().millisecondsSinceEpoch}',
          'latitud': _currentPosition!.latitude,
          'longitud': _currentPosition!.longitude,
          'ruta': 'D',
          'estado': 'en_ruta',
          'ultima_actualizacion': FieldValue.serverTimestamp(),
          'rol': 'conductor',
        });
        print('✅ Documento nuevo creado: $_documentId');
      }

      _startPeriodicUpdate();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transmisión iniciada')));
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isTransmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _stopTransmission() async {
    setState(() => _isTransmitting = false);

    if (_documentId != null) {
      await FirebaseFirestore.instance
          .collection('unidades')
          .doc(_documentId)
          .update({
            'estado': 'detenido',
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
      _documentId = null;
    }

    _updateTimer?.cancel();
    _updateTimer = null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transmisión detenida')));
  }

  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isTransmitting) {
        timer.cancel();
        return;
      }

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (_documentId != null) {
          await FirebaseFirestore.instance
              .collection('unidades')
              .doc(_documentId)
              .update({
                'latitud': position.latitude,
                'longitud': position.longitude,
                'ultima_actualizacion': FieldValue.serverTimestamp(),
              });
          print(
            '🔄 Ubicación actualizada cada 3s: ${position.latitude}, ${position.longitude}',
          );
        }
      } catch (e) {
        print('❌ Error actualizando ubicación: $e');
      }
    });
  }

  // --- Simulación de latencia (para la UI) ---

  Timer? _latencyTimer;
  void _simulateLatency() {
    _latencyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _latency =
              20 + DateTime.now().millisecond % 80; // Valor entre 20 y 100 ms
        });
      }
    });
  }

  // --- Widgets de la interfaz (mejorada la responsividad) ---

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de la pantalla para hacer ajustes responsivos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con gradiente radial
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.33,
                    colors: [Colors.black.withValues(alpha: 0), Colors.black],
                  ),
                ),
              ),
            ),
          ),
          // Línea verde superior sutil (responsiva)
          Positioned(
            left: screenWidth * 0.04,
            top: 0,
            child: Container(
              width: screenWidth * 0.92,
              height: 2,
              color: const Color(0x1900FF00),
            ),
          ),
          // Contenido principal con SafeArea (evita que se solape con la muesca)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 24,
                0,
                isSmallScreen ? 16 : 24,
                MediaQuery.of(context).padding.bottom +
                    (isSmallScreen ? 16 : 24),
              ),
              child: Column(
                children: [
                  // --- Header (más compacto en pantallas pequeñas) ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 24,
                    ),
                    child: Column(
                      children: [
                        // Badge "UNIDAD: LÍNEA 15 - A"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFF424654)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: Color(0xFF424654),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _unidadInfo,
                                style: TextStyle(
                                  color: const Color(0xFF424654),
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Título "TRANSMISIÓN"
                        Text(
                          'TRANSMISIÓN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Indicador "LISTO PARA LA TRANSMISIÓN"
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00FF00),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isTransmitting
                                  ? 'TRANSMITIENDO'
                                  : 'LISTO PARA LA TRANSMISIÓN',
                              style: TextStyle(
                                color: const Color(0xFF737785),
                                fontSize: isSmallScreen ? 9 : 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.2,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // --- Botón central pulsante (tamaño responsivo) ---
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Anillos orbitales (tamaños responsivos)
                              Container(
                                width: screenWidth * 0.87,
                                height: screenWidth * 0.87,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0x0C00FF00),
                                  ),
                                ),
                              ),
                              Container(
                                width: screenWidth * 0.72,
                                height: screenWidth * 0.72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0x1900FF00),
                                  ),
                                ),
                              ),
                              // Glow detrás del botón
                              Container(
                                width: screenWidth * 0.57,
                                height: screenWidth * 0.57,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x1A00FF00),
                                ),
                              ),
                              // Botón principal (tamaño responsivo)
                              GestureDetector(
                                onTap: _toggleTransmission,
                                child: Container(
                                  width: screenWidth * 0.57,
                                  height: screenWidth * 0.57,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isTransmitting
                                            ? Colors.red.withValues(alpha: 0.7)
                                            : const Color(0x7F00FF00),
                                        blurRadius: 60,
                                        spreadRadius: -15,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_bus,
                                        color: Colors.black,
                                        size: isSmallScreen ? 28 : 36,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isTransmitting
                                            ? 'DETENER\nTRANSMISIÓN'
                                            : 'INICIAR\nTRANSMISIÓN',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: isSmallScreen ? 16 : 20,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- Footer: Métricas y versión ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 32,
                      vertical: isSmallScreen ? 16 : 24,
                    ),
                    child: Column(
                      children: [
                        // Métricas de telemetría
                        Container(
                          padding: const EdgeInsets.only(top: 24),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0x33424654)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LATENCIA',
                                    style: TextStyle(
                                      color: Color(0xFF737785),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.55,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    '${_latency} ms',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'SEÑAL',
                                    style: TextStyle(
                                      color: Color(0xFF737785),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.55,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    _isTransmitting ? '95%' : '0%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Texto de consumo y versión
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security,
                              color: Color(0xFF00FF00),
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Consumo seguro (< 50MB/día)',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            _appVersion,
                            style: const TextStyle(
                              color: Color(0xFF737785),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
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
