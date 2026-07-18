import 'package:flutter/material.dart';

class PantallaRutas extends StatelessWidget {
  const PantallaRutas({super.key});

  @override
  Widget build(BuildContext context) {
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
              children: const [
                SizedBox(width: 8),
                Text(
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
          
          // --- Contenido de la pestaña Rutas ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // 1. Tarjeta de Inputs (Origen y Destino)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC3C6D6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Input de Origen
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Color(0xFF007232), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Tu ubicación actual',
                                  hintStyle: const TextStyle(color: Color(0xFF424654), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Divisor con línea sutil
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 16,
                              child: VerticalDivider(color: Color(0xFFC3C6D6), thickness: 1),
                            ),
                          ),
                        ),
                        
                        // Input de Destino
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFE53935), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: '¿A dónde vas?',
                                  hintStyle: const TextStyle(color: Color(0xFF8A8D9F), fontSize: 14),
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

                  const SizedBox(height: 12),

                  // 2. Botón "Seleccionar en el mapa"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        // Aquí irá la lógica para volver al mapa
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.map_outlined, color: Color(0xFF424654), size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Seleccionar en el mapa',
                              style: TextStyle(
                                color: Color(0xFF1A1C1C),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Color(0xFFC3C6D6)),
                  ),

                  // 3. Destinos Recientes / POIs
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Sugerencias',
                      style: TextStyle(
                        color: Color(0xFF8A8D9F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Lista de paraderos/destinos estratégicos
                  _buildDestinoItem(Icons.school, 'Universidad Tecnológica del Perú', 'Sede Central'),
                  _buildDestinoItem(Icons.shopping_bag, 'Mall Plaza', 'Av. América Oeste'),
                  _buildDestinoItem(Icons.park, 'Plaza de Armas', 'Centro Histórico'),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para no repetir código en la lista
  Widget _buildDestinoItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF424654), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A1C1C),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF8A8D9F),
          fontSize: 13,
        ),
      ),
      onTap: () {
        // Lógica de cálculo de proximidad
      },
    );
  }
}