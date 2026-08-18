import 'package:flutter/material.dart';
import 'package:patas_al_dia/presentation/theme/tema_app.dart';

/// `Card` cuyo contenido se ve siempre igual que en modo claro (fondo
/// Durazno, texto Café texto oscuro), sin importar si el tema general de
/// la app está en modo oscuro — las tarjetas de esta app son un color de
/// acento fijo, no un "fondo" que deba invertirse con el tema.
class TarjetaClara extends StatelessWidget {
  final Widget child;
  const TarjetaClara({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(data: temaClaro, child: Card(child: child));
  }
}
