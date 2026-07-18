import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trux_mvp/AppData.dart'; // Ajusta este import según donde tengas AppData
import 'Rutas_data.dart'; // Ajusta este import según tu estructura de carpetas

class PantallaRutas extends StatefulWidget {
  const PantallaRutas({super.key});

  @override
  State<PantallaRutas> createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  // Obtenemos los destinos reales desde tu archivo de datos
  final List<Destino> _destinosSugeridos = RutasData.getDestinos();

  // Función para evaluar la proximidad al tocar un destino
  void _evaluarDestino(BuildContext context, Destino destino) {
    // 1. Obtenemos la ubicación actual del usuario (simulada o de AppData)
    // Asumiendo que AppData.currentPosition tiene la ubicación en tiempo real
    LatLng ubicacionUsuario = AppData.currentPosition != null 
        ? LatLng(AppData.currentPosition!.latitude, AppData.currentPosition!.longitude)
        : const LatLng(-8.115, -79.028); // Fallback en caso de null

    // 2. Usamos tu función matemática de RutasData (Tolerancia de 30 metros)
    bool estaEnRuta = RutasData.isUserOnRoute(ubicacionUsuario, toleranceMeters: 30.0);

    // 3. Mostramos el resultado en pantalla
    ScaffoldMessenger.of(context).clearSnackBars();
    if (estaEnRuta) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Excelente! Estás a menos de 30m del paradero para ir a ${destino.nombre}.'),
          backgroundColor: const Color(0xFF007232),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estás lejos de la ruta. Dirígete a la avenida principal para ir a ${destino.nombre}.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                        Row(
                          children: const [
                            Icon(Icons.my_location, color: Color(0xFF007232), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Tu ubicación actual',
                                  hintStyle: TextStyle(color: Color(0xFF424654), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Color(0xFFE53935), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: '¿A dónde vas?',
                                  hintStyle: TextStyle(color: Color(0xFF8A8D9F), fontSize: 14),
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
                        // TODO: Implementar lógica de regreso al mapa
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

                  // 3. Destinos Recientes dinámicos
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Destinos de la ruta',
                      style: TextStyle(
                        color: Color(0xFF8A8D9F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Aquí iteramos sobre la lista real de RutasData
                  ..._destinosSugeridos.map((destino) => _buildDestinoItem(context, destino)),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar ahora recibe un objeto Destino completo
  Widget _buildDestinoItem(BuildContext context, Destino destino) {
    // Asignamos iconos basados en el índice o nombre para darle variedad visual
    IconData icon = Icons.place;
    if (destino.puntoIndice == 238) icon = Icons.shopping_bag; // Mall Plaza
    if (destino.puntoIndice == 119) icon = Icons.park; // Parque Amauta
    if (destino.puntoIndice == 0 || destino.puntoIndice == 356) icon = Icons.route; // Extremos

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
        destino.nombre,
        style: const TextStyle(
          color: Color(0xFF1A1C1C),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        destino.direccion,
        style: const TextStyle(
          color: Color(0xFF8A8D9F),
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _evaluarDestino(context, destino),
    );
  }
}