import 'package:flutter/material.dart';

/// Ícono de un reporte de mascota extraviada: la misma pata del navbar
/// (`Icons.pets`), encerrada en un triángulo de advertencia — amarillo si
/// es un reporte de mascota perdida, azul si es de mascota encontrada.
/// Compartido entre `MapaScreen` (marcadores, burbuja, chips de "sin
/// ubicación") y `DetalleReporteMascotaExtraviadaScreen` (mini-mapa), para
/// que el mismo tipo de reporte se vea igual en toda la app — ver
/// `iconoTipoReporte.md`.
class IconoTipoReporte extends StatelessWidget {
  final String tipo;
  final double size;

  const IconoTipoReporte({super.key, required this.tipo, this.size = 36});

  static const _colorPerdido = Colors.amber;
  static const _colorEncontrado = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final color = tipo == 'perdido' ? _colorPerdido : _colorEncontrado;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Triángulo dibujado a mano (no Icons.change_history) — el ícono
          // de Material no rellena sólido hasta el borde en todos los
          // tamaños, dejando un hueco visible dentro. Con CustomPainter el
          // relleno queda garantizado y el centro geométrico es exacto
          // (ápice en x = size/2), sin depender de cómo esté recortado el
          // glyph del ícono dentro de su propio recuadro.
          CustomPaint(
            size: Size(size, size),
            painter: _TrianguloRelleno(color),
          ),
          // El glyph de Icons.pets no queda centrado dentro de su propio
          // recuadro (el dibujo de la pata está corrido hacia la izquierda
          // dentro del ícono de Material) — este desplazamiento horizontal
          // lo compensa. El vertical baja la pata al cuerpo visible del
          // triángulo (más angosto arriba, más ancho abajo).
          Padding(
            padding: EdgeInsets.only(top: size * 0.2, left: size * 0.015),
            child: Icon(Icons.pets, color: Colors.black87, size: size * 0.4),
          ),
        ],
      ),
    );
  }
}

class _TrianguloRelleno extends CustomPainter {
  final Color color;
  const _TrianguloRelleno(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianguloRelleno oldDelegate) =>
      oldDelegate.color != color;
}
