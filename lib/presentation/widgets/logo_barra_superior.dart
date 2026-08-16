import 'package:flutter/material.dart';

/// Logo de la app para el `leading` del AppBar de las tres pantallas
/// principales del navbar (Mascotas, Agenda, Mapa) — las únicas sin flecha
/// de "atrás" compitiendo por ese espacio.
class LogoBarraSuperior extends StatelessWidget {
  const LogoBarraSuperior({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset('assets/images/logo_patas_al_dia.png'),
    );
  }
}
