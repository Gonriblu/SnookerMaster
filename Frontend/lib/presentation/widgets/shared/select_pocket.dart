import 'package:flutter/material.dart';

class SelectPocketScreen extends StatefulWidget {
  const SelectPocketScreen({super.key});

  @override
  State<SelectPocketScreen> createState() => _SelectPocketScreenState();
}

class _SelectPocketScreenState extends State<SelectPocketScreen> {
  String? _selectedPocketId;

  // Definir las posiciones de las Pockets
  final List<Offset> pocketPositions = [
    const Offset(0.05, 0.03), // Tronera superior izquierda
    const Offset(0.87, 0.03), // Tronera superior derecha
    const Offset(0.05, 0.52), // Tronera medio izquierda
    const Offset(0.87, 0.52), // Tronera medio derecha
    const Offset(0.05, 1), // Tronera inferior izquierda
    const Offset(0.87, 1), // Tronera inferior derecha
  ];

  // Mapa para los identificadores de troneras
  final Map<int, String> pocketIds = {
    1: 'TopLeft',
    2: 'TopRight',
    3: 'MediumLeft',
    4: 'MediumRight',
    5: 'BottomLeft',
    6: 'BottomRight',
  };

  // Mapa para mostrar mensajes en español
  final Map<String, String> pocketLabels = {
    'TopLeft': 'tronera superior izquierda',
    'TopRight': 'tronera superior derecha',
    'MediumLeft': 'tronera medio izquierda',
    'MediumRight': 'tronera medio derecha',
    'BottomLeft': 'tronera inferior izquierda',
    'BottomRight': 'tronera inferior derecha',
  };

  final double pocketSize = 50.0; // Tamaño del "botón" de tronera

  void _onPocketTap(Offset pocketPosition) {
    final selectedPocketId = pocketIds[pocketPositions.indexOf(pocketPosition) + 1];

    setState(() {
      _selectedPocketId = selectedPocketId;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Seleccionaste la ${pocketLabels[selectedPocketId!]}'),
    ));
  }

  void _confirmSelection() {
    if (_selectedPocketId != null) {
      Navigator.of(context).pop(_selectedPocketId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una tronera antes de continuar.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Tronera'),
      ),
      body: Center(
        child: Stack(
          children: [
            // Imagen de la mesa de billar
            Image.asset(
              'lib/config/assets/images/snooker_table_map.png',
              width: 325,
              height: 620,
              fit: BoxFit.cover,
            ),
            // Troneras interactivas
            ...pocketPositions.map((position) {
              final pocketIndex = pocketPositions.indexOf(position) + 1;
              final pocketId = pocketIds[pocketIndex];

              return Positioned(
                left: position.dx * 350 - pocketSize / 2, // Ajuste para el tamaño de la imagen
                top: position.dy * 600 - pocketSize / 2,
                child: GestureDetector(
                  onTap: () => _onPocketTap(position),
                  child: Container(
                    width: pocketSize,
                    height: pocketSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedPocketId != null && pocketId == _selectedPocketId
                            ? Colors.red // Tronera seleccionada resaltada
                            : Colors.green, // Tronera sin seleccionar
                        width: 3,
                      ),
                      color: Colors.white.withOpacity(0.6), // Hacerlo semitransparente
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        pocketIndex.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmSelection,
        tooltip: 'Confirmar selección',
        child: const Icon(Icons.check),
      ),
    );
  }
}
