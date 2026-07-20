import 'package:flutter/material.dart';

class PantallaTrofeo extends StatelessWidget {
  const PantallaTrofeo({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          color: const Color(0xFFF9F9F9),
          child: Column(
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
                      'Trofeo',
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
              // --- Contenido de la pestaña Trofeo (placeholder) ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Por ahora solo un placeholder
                      const Center(
                        child: Text(
                          'Aquí irá el contenido de Trofeo',
                          style: TextStyle(color: Color(0xFF424654)),
                        ),
                      ),
                      // ... más widgets luego (según tu Figma)
                    ],
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
