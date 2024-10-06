import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: InteractiveViewer(
            panEnabled: true, // Permitir arrastrar la imagen
            boundaryMargin: const EdgeInsets.all(20.0), // Margen alrededor de la imagen para que sea accesible
            minScale: 0.5, // Escala mínima de zoom
            maxScale: 4.0, // Escala máxima de zoom
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ),
    );
  }
}