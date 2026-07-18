import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trux_mvp/AppData.dart'; 
import 'Rutas_data.dart'; 
import 'MapaDetalleRuta.dart'; // Agrega esta línea arriba

class PantallaRutas extends StatefulWidget {
  final VoidCallback? onVolverAlMapa; 

  const PantallaRutas({super.key, this.onVolverAlMapa});

  @override
  State<PantallaRutas> createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  final List<Destino> _todosLosDestinos = RutasData.getDestinos();
  List<Destino> _destinosFiltrados = [];
  final List<Destino> _busquedasRecientes = []; // 1. Memoria local añadida
  final TextEditingController _buscadorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _destinosFiltrados = _todosLosDestinos; 
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  void _filtrarDestinos(String query) {
    setState(() {
      if (query.isEmpty) {
        _destinosFiltrados = _todosLosDestinos;
      } else {
        _destinosFiltrados = _todosLosDestinos
            .where((destino) =>
                destino.nombre.toLowerCase().contains(query.toLowerCase()) ||
                destino.direccion.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // 2. Nueva función: Tarjeta Modal en lugar de SnackBar
  void _mostrarTarjetaResultados(BuildContext context, Destino destino) {
    // A. Guardar en recientes sin duplicar
    setState(() {
      _busquedasRecientes.removeWhere((d) => d.nombre == destino.nombre);
      _busquedasRecientes.insert(0, destino);
      if (_busquedasRecientes.length > 4) _busquedasRecientes.removeLast();
    });

    // B. Cálculos Matemáticos con Rutas_data
    LatLng ubicacionUsuario = AppData.currentPosition != null 
        ? LatLng(AppData.currentPosition!.latitude, AppData.currentPosition!.longitude)
        : const LatLng(-8.115, -79.028); 

    // Mock del micro Ícaro (Pronto vendrá de Firestore)
    LatLng ubicacionIcaroMock = const LatLng(-8.112, -79.030); 
    
    double distanciaAlMicro = RutasData.calcularDistanciaMetros(ubicacionUsuario, ubicacionIcaroMock);
    int etaMinutos = RutasData.calcularETA(distanciaAlMicro);

    // C. Mostrar el BottomSheet (Diseño Figma)
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ruta sugerida', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007232).withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text(
                      '$etaMinutos min', 
                      style: const TextStyle(color: Color(0xFF007232), fontWeight: FontWeight.bold)
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Información del Micro
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0040A1), 
                  child: Icon(Icons.directions_bus, color: Colors.white)
                ),
                title: Text(
                  'Micro ${RutasData.rutaPrincipal.empresa} (Línea ${RutasData.rutaPrincipal.letra})', 
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                ),
                subtitle: Text('A ${(distanciaAlMicro / 1000).toStringAsFixed(1)} km de distancia'),
              ),
              
              const SizedBox(height: 24),
              
              // Botón de Acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0040A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Cierra el modal inferior
                    
                    // Navega a la nueva pantalla dedicada pasando el destino elegido
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapaDetalleRuta(destinoSeleccionado: destino),
                      ),
                    );
                  },
                  child: const Text('Ver detalles en el mapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lógica visual: Si no se ha escrito nada y hay recientes, muestra recientes.
    bool mostrandoRecientes = _buscadorController.text.isEmpty && _busquedasRecientes.isNotEmpty;
    List<Destino> listaAMostrar = mostrandoRecientes ? _busquedasRecientes : _destinosFiltrados;

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
              border: Border(bottom: BorderSide(color: Color(0xFFC3C6D6), width: 1)),
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
                const Text('Planear ruta', style: TextStyle(color: Color(0xFF1A1C1C), fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
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
                            border: Border.all(color: const Color(0xFF0040A1), width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.radio_button_checked, color: Color(0xFFC3C6D6), size: 16),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      enabled: false, // Simula "Mi ubicación"
                                      decoration: InputDecoration(
                                        hintText: 'Mi ubicación',
                                        hintStyle: TextStyle(color: Color(0xFF1A1C1C), fontSize: 14),
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
                                  child: SizedBox(height: 12, child: VerticalDivider(color: Color(0xFFC3C6D6), thickness: 1)),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.circle, color: Color(0xFF0040A1), size: 16),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _buscadorController,
                                      onChanged: _filtrarDestinos,
                                      decoration: const InputDecoration(
                                        hintText: '¿Hacia dónde vas?',
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
                      ),
                      // Botón de Intercambio
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F0FF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.swap_vert, color: Color(0xFF0040A1)),
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
                        _buildQuickActionChip(Icons.home, 'Casa', isPrimary: true),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(Icons.work_outline, 'Trabajo'),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(Icons.add, 'Guardar'),
                      ],
                    ),
                  ),

                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Divider(color: Color(0xFFC3C6D6))),

                  // --- 5. Lista de Resultados / Recientes ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      mostrandoRecientes ? 'RECIENTES' : 'RESULTADOS', 
                      style: const TextStyle(color: Color(0xFF8A8D9F), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)
                    ),
                  ),

                  if (listaAMostrar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No se encontraron destinos.', style: TextStyle(color: Color(0xFF8A8D9F)))),
                    )
                  else
                    ...listaAMostrar.map((destino) => _buildDestinoItem(context, destino, mostrandoRecientes)),
                  
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

  // Widget para los botones (Casa, Trabajo)
  Widget _buildQuickActionChip(IconData icon, String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF5DFD8A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isPrimary ? const Color(0xFF007232) : const Color(0xFF424654)),
          const SizedBox(width: 6),
          Text(
            label, 
            style: TextStyle(
              color: isPrimary ? const Color(0xFF007232) : const Color(0xFF1A1C1C),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )
          ),
        ],
      ),
    );
  }

  // Elemento individual de la lista
  Widget _buildDestinoItem(BuildContext context, Destino destino, bool isRecent) {
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
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(destino.nombre, style: const TextStyle(color: Color(0xFF1A1C1C), fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(destino.direccion, style: const TextStyle(color: Color(0xFF8A8D9F), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.north_west, color: Color(0xFF8A8D9F), size: 20), // Flecha diagonal
          ],
        ),
      ),
    );
  }
}