import 'dart:typed_data';
import 'package:flutter/material.dart';

class MinimapScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const MinimapScreen({super.key, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimapa'),
      ),
      body: FutureBuilder<Uint8List>(
        future: Future.value(imageBytes), // Return the image bytes directly
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(), // Show a loading indicator while waiting
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar la imagen'), // Handle the error
            );
          } else if (snapshot.hasData) {
            return Center(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              ),
            );
          } else {
            return const Center(
              child: Text('No hay imagen disponible'), // Handle the case where there is no data
            );
          }
        },
      ),
    );
  }
}
