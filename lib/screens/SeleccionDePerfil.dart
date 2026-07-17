import 'package:flutter/material.dart';
import 'MapaPrincipal.dart';
import 'ModoConductorSatelite.dart';

class SeleccionDePerfil extends StatelessWidget {
  const SeleccionDePerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Fondo de la pantalla
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0, // Sin sombra en la AppBar por defecto
        centerTitle: true,
        title: const Text(
          'Trux',
          style: TextStyle(
            color: Color(0xFF0040A1), // Azul del header
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        // Sombra sutil inferior (simula la del diseño)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0x0C000000), // Sombra muy suave
          ),
        ),
      ),
      body: Stack(
        // Stack para colocar los círculos decorativos detrás del contenido
        children: [
          // --- Círculo decorativo superior derecho (azul) ---
          Positioned(
            right: -96,
            top: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: const BoxDecoration(
                color: Color(0x0C0040A1), // Azul con 5% de opacidad
                shape: BoxShape.circle,
              ),
            ),
          ),
          // --- Círculo decorativo inferior izquierdo (verde) ---
          Positioned(
            left: -128,
            bottom: 78, // Ajustado para que coincida con el diseño
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                color: Color(0x195DFD8A), // Verde con 10% de opacidad
                shape: BoxShape.circle,
              ),
            ),
          ),
          // --- Contenido principal (scrollable) ---
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título principal
                const Text(
                  '¿Cómo usarás Trux hoy?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1A1C1C),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtítulo
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Selecciona tu perfil para personalizar tu\nexperiencia de viaje en Trujillo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF424654),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      height: 1.43,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tarjetas de selección de perfil (en una columna)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      // Tarjeta "Soy Pasajero"
                      _buildProfileCard(
                        icon: Icons.person,
                        title: 'Soy Pasajero',
                        subtitle: 'Encuentra tus micros',
                        titleColor: const Color(0xFF0040A1),
                        iconBackground: const Color(0xFFDAE2FF),
                        onTap: () {
                          // Navega al Mapa Principal
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MapaPrincipal(rol: 'pasajero'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta "Soy Conductor"
                      _buildProfileCard(
                        icon: Icons.directions_car, // Placeholder
                        title: 'Soy Conductor',
                        subtitle: 'Modo Low Data',
                        titleColor: const Color(0xFF006D2F),
                        iconBackground: const Color(0xFF5DFD8A),
                        onTap: () {
                          // Navega al Mapa Principal
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ModoConductorSatelite(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Ilustración decorativa (placeholder)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC3C6D6)),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Color(0xFF0040A1),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget privado para construir cada tarjeta de perfil
  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC3C6D6)),
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
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: titleColor, size: 32),
            ),
            const SizedBox(width: 24),
            // Textos (título y subtítulo)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF424654),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      height: 1.43,
                    ),
                  ),
                ],
              ),
            ),
            // Flecha derecha
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFC3C6D6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
