/// Logo NEXORA — escudo dorado con "N", dibujado a mano con [CustomPainter].
///
/// Se dibuja en código (no se decodifica un SVG/PNG en runtime) porque el
/// proyecto mantiene la regla de cero dependencias externas: no hay paquete
/// de renderizado de SVG en pubspec.yaml. Los archivos en `assets/brand/`
/// son la fuente de verdad para generar los íconos de la app (ver
/// `scripts/make_app_icons.py`); este widget es la versión "viva" que se
/// ve dentro de la UI (splash, cabecera del dashboard, etc).
library;

import 'package:flutter/material.dart';

import 'theme.dart';

class NexoraLogo extends StatelessWidget {
  const NexoraLogo({super.key, this.size = 120, this.showRing = true});

  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _NexoraShieldPainter(showRing: showRing)),
  );
}

class _NexoraShieldPainter extends CustomPainter {
  _NexoraShieldPainter({required this.showRing});

  final bool showRing;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240;
    canvas.save();
    canvas.scale(scale);
    const w = 240.0;
    const h = 240.0;
    final center = Offset(w / 2, h / 2 + 4);

    if (showRing) {
      final ringPaint = Paint()
        ..color = nexoraBlue.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(center, w * 0.46, ringPaint);
    }

    // Escudo: tapa redondeada arriba, se cierra en punta abajo.
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..cubicTo(w * 0.68, h * 0.10, w * 0.80, h * 0.16, w * 0.80, h * 0.16)
      ..lineTo(w * 0.80, h * 0.46)
      ..cubicTo(w * 0.80, h * 0.68, w * 0.68, h * 0.83, w * 0.5, h * 0.92)
      ..cubicTo(w * 0.32, h * 0.83, w * 0.20, h * 0.68, w * 0.20, h * 0.46)
      ..lineTo(w * 0.20, h * 0.16)
      ..cubicTo(w * 0.20, h * 0.16, w * 0.32, h * 0.10, w * 0.5, h * 0.10)
      ..close();

    final shieldFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF12224A), Color(0xFF0A0F24)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shield, shieldFill);

    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = nexoraGold;
    canvas.drawPath(shield, shieldStroke);

    // Borde interno sutil, separado del borde exterior (efecto "doble filo").
    final inner = Path()
      ..moveTo(w * 0.5, h * 0.155)
      ..cubicTo(
        w * 0.635,
        h * 0.155,
        w * 0.735,
        h * 0.205,
        w * 0.735,
        h * 0.205,
      )
      ..lineTo(w * 0.735, h * 0.45)
      ..cubicTo(w * 0.735, h * 0.64, w * 0.635, h * 0.765, w * 0.5, h * 0.845)
      ..cubicTo(w * 0.365, h * 0.765, w * 0.265, h * 0.64, w * 0.265, h * 0.45)
      ..lineTo(w * 0.265, h * 0.205)
      ..cubicTo(w * 0.265, h * 0.205, w * 0.365, h * 0.155, w * 0.5, h * 0.155)
      ..close();
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = nexoraGold.withValues(alpha: 0.45),
    );

    // Pequeño diamante ornamental sobre el escudo.
    final gem = Path()
      ..moveTo(w * 0.5, h * 0.015)
      ..lineTo(w * 0.5 + 7, h * 0.06)
      ..lineTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.5 - 7, h * 0.06)
      ..close();
    canvas.drawPath(gem, Paint()..color = nexoraGoldLight);

    // "N" en el centro.
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          fontSize: h * 0.34,
          fontWeight: FontWeight.w800,
          color: nexoraGoldLight,
          fontFamily: 'serif',
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        w / 2 - textPainter.width / 2,
        h * 0.5 - textPainter.height / 2 + 2,
      ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NexoraShieldPainter oldDelegate) => false;
}
