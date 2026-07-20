import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trux_mvp/AppData.dart';
import 'SeleccionDePerfil.dart';

class SplashScreenTrux extends StatefulWidget {
  const SplashScreenTrux({super.key});

  @override
  State<SplashScreenTrux> createState() => _SplashScreenTruxState();
}

class _SplashScreenTruxState extends State<SplashScreenTrux> {
  bool _isLoading = true; // Muestra "Cargando ubicación..."
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _requestLocationAndNavigate();
  }

  Future<void> _requestLocationAndNavigate() async {
    // 1. Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado.';
          _isLoading = false;
        });
        // Esperar 3 segundos y navegar igual (sin ubicación)
        await Future.delayed(const Duration(seconds: 3));
        _navigateToNext();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Permiso bloqueado permanentemente.';
        _isLoading = false;
      });
      await Future.delayed(const Duration(seconds: 3));
      _navigateToNext();
      return;
    }

    // 2. Obtener ubicación
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Guardar en la variable global
      AppData.currentPosition = position;
      print(
        '✅ Ubicación obtenida en Splash: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('❌ Error al obtener ubicación en Splash: $e');
      setState(() {
        _errorMessage = 'Error al obtener ubicación.';
      });
    }

    // 3. Esperar un momento para que se vea el Splash y luego navegar
    await Future.delayed(const Duration(seconds: 1));
    _navigateToNext();
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SeleccionDePerfil()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Stack(
            children: [
              // ... (todos tus círculos decorativos, igual que antes) ...
              // --- Círculo decorativo superior izquierdo ---
              Positioned(
                left: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.71,
                      colors: [
                        const Color(0x0C0056D2),
                        const Color(0x000056D2),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Círculo decorativo inferior derecho ---
              Positioned(
                right: -40,
                bottom: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.71,
                      colors: [
                        const Color(0x0C0056D2),
                        const Color(0x000056D2),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Contenido principal ---
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056D2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Trux',
                          style: TextStyle(
                            color: Color(0xFF0056D2),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.60,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Opacity(
                      opacity: 0.7,
                      child: Text(
                        'TRUJILLO APP',
                        style: TextStyle(
                          color: Color(0xFF737785),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.20,
                          height: 1.33,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Indicador de carga o mensaje de error
                    if (_isLoading) ...[
                      const CircularProgressIndicator(color: Color(0xFF0056D2)),
                      const SizedBox(height: 16),
                      const Text(
                        'Conectando tu ciudad...',
                        style: TextStyle(
                          color: Color(0xFF737785),
                          fontSize: 14,
                        ),
                      ),
                    ] else if (_errorMessage.isNotEmpty) ...[
                      Icon(Icons.error_outline, color: Colors.red[300]),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Puedes continuar sin ubicación.',
                        style: TextStyle(
                          color: Color(0xFF737785),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
