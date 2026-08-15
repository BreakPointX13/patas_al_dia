import 'dart:io';
import 'package:flutter/material.dart';

/// Muestra una imagen local a pantalla completa, con zoom (pellizcar para
/// acercar/alejar) vía InteractiveViewer. No requiere ningún paquete nuevo.
class VisorImagenScreen extends StatelessWidget {
  final String filePath;
  final String titulo;

  const VisorImagenScreen({
    super.key,
    required this.filePath,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(titulo),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(filePath)),
        ),
      ),
    );
  }
}
