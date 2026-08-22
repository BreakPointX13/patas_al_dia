import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Separador visual entre grupos de datos de una mascota (formulario y
/// ficha de detalle): una línea Durazno a cada lado con un ícono centrado.
class SeparadorSeccionFicha extends StatelessWidget {
  final Widget icono;
  const SeparadorSeccionFicha({super.key, required this.icono});

  /// Ícono de la sección "Mascota" — el mismo `Icons.pets` del navbar
  /// inferior, no un SVG (esa sección no tiene ícono propio diseñado).
  static const _colorIcono = Color(0xFFD06D1F);
  factory SeparadorSeccionFicha.mascota({Key? key}) => SeparadorSeccionFicha(
    key: key,
    icono: const Icon(Icons.pets, color: _colorIcono, size: 26),
  );

  /// Ícono de la sección "Identificación" (chip, esterilización, etc.).
  factory SeparadorSeccionFicha.identificacion({Key? key}) =>
      SeparadorSeccionFicha(
        key: key,
        icono: SvgPicture.asset(
          'assets/icons/ficha/identificacion.svg',
          width: 26,
          height: 26,
        ),
      );

  /// Ícono de la sección "Datos" (peso, raza, fecha de nacimiento, etc.).
  factory SeparadorSeccionFicha.datos({Key? key}) => SeparadorSeccionFicha(
    key: key,
    icono: SvgPicture.asset(
      'assets/icons/ficha/datos.svg',
      width: 26,
      height: 26,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFFF3C98F), thickness: 1.5),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: icono),
          const Expanded(
            child: Divider(color: Color(0xFFF3C98F), thickness: 1.5),
          ),
        ],
      ),
    );
  }
}
