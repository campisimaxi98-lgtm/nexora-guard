/// Planeta digital animado de NEXORA — marca de la portada y del splash.
///
/// 100% dibujado con CustomPainter (cero assets, cero dependencias): una
/// esfera con curvas "digitales" que rotan, dos anillos en órbita (dorado y
/// azul grisáceo), polos en deriva lenta y un campo de estrellas fijo con
/// parpadeo. Las posiciones son determinísticas (un solo `Random` con seed
/// fijo) para que el dibujo sea estable entre frames y en tests.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class NexoraPlanet extends StatefulWidget {
  const NexoraPlanet({
    super.key,
    this.size = 220,
    this.slow = true,
  });

  /// Diámetro de la esfera (los anillos la rodean y pueden sobresalir).
  final double size;

  /// `true` anima la rotación; `false` congela el dibujo (ahorro en
  /// pantallas que no necesitan movimiento perpetuo).
  final bool slow;

  @override
  State<NexoraPlanet> createState() => _NexoraPlanetState();
}

class _NexoraPlanetState extends State<NexoraPlanet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 24000),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = CustomPaint(
      painter: _PlanetPainter(phase: _spin.value),
      size: Size.square(widget.size),
    );
    if (!widget.slow) return RepaintBoundary(child: core);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          painter: _PlanetPainter(phase: _spin.value),
          size: Size.square(widget.size),
        ),
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  _PlanetPainter({required this.phase});

  /// 0..1 dentro del ciclo de 24 s.
  final double phase;

  static const _stars = <(double, double)>[
    (0.06, 0.10), (0.16, 0.26), (0.28, 0.08), (0.40, 0.16), (0.55, 0.05),
    (0.68, 0.14), (0.82, 0.07), (0.92, 0.20), (0.10, 0.42), (0.30, 0.34),
    (0.88, 0.44), (0.05, 0.62), (0.22, 0.70), (0.94, 0.64), (0.12, 0.86),
    (0.34, 0.90), (0.58, 0.94), (0.78, 0.84), (0.50, 0.78), (0.70, 0.56),
    (0.42, 0.50), (0.62, 0.32), (0.52, 0.66), (0.86, 0.80), (0.05, 0.22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final center = Offset(w * 0.5, h * 0.5);
    final planetRadius = w * 0.30;
    final t = phase * 2 * math.pi;

    // Estrellas fijas con parpadeo lento (independientes de la rotación).
    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final (sx, sy) = _stars[i];
      final twinkle =
          0.05 +
          0.10 *
              (0.5 + 0.5 * math.sin(t * 0.6 + i * 1.71));
      star.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(Offset(w * sx, h * sy), 1.0, star);
    }

    // Resplandor ambiental dorado (muy sutil) detrás del planeta.
    canvas.drawCircle(
      center,
      planetRadius * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            nexoraGold.withValues(alpha: 0.10),
            nexoraGold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: planetRadius * 2.6)),
    );

    // ── Esfera ──
    final sphere = Rect.fromCircle(center: center, radius: planetRadius);
    canvas.drawCircle(center, planetRadius, Paint()..color = const Color(0xFF141D38));
    final bodyShader = RadialGradient(
      center: const Alignment(-0.6, -0.7),
      radius: 1.4,
      colors: const [
        Color(0xFF23345E),
        Color(0xFF121B36),
        Color(0xFF0A0F24),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(sphere);
    canvas.drawCircle(center, planetRadius, Paint()..shader = bodyShader);

    // Resplandor fino en el limbo superior-izquierdo.
    final rim = Paint()
      ..shader = RadialGradient(
        colors: [
          nexoraBlue.withValues(alpha: 0.55),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center.translate(-planetRadius * 0.45, -planetRadius * 0.45),
          radius: planetRadius * 0.8,
        ),
      );
    canvas.drawCircle(center, planetRadius, rim);

    // ── Curvas "digitales" del planeta (meridianos) que rotan ──
    // Se dibujan rotando el lienzo alrededor del centro según `t`.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 0.35);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = nexoraBlue.withValues(alpha: 0.40);
    final clipPath = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: planetRadius));
    canvas.save();
    canvas.clipPath(clipPath);
    for (var k = 0; k < 5; k++) {
      final offset = -planetRadius + k * (planetRadius * 0.5);
      canvas.drawRect(
        Rect.fromLTWH(offset, -planetRadius, planetRadius * 0.32, planetRadius * 2),
        line,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: planetRadius * 2,
        height: planetRadius * 0.9,
      ),
      line,
    );
    canvas.restore();

    // Anillo "puente" brillante que cruza la esfera (efecto digital).
    final bridge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = nexoraGoldLight.withValues(alpha: 0.35);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset.zero,
        width: planetRadius * 2,
        height: planetRadius * 1.15,
      ),
      t * 0.35 + 0.15,
      1.4,
      false,
      bridge,
    );
    canvas.restore();

    // ── Anillos orbitales (elipse inclinada) ──
    final ringStyle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var r = 0; r < 2; r++) {
      final rx = planetRadius * (1.55 + r * 0.85);
      final ry = rx * 0.34;
      final ringColor = r == 0 ? nexoraGold : nexoraBlue;
      ringStyle.color = ringColor.withValues(alpha: r == 0 ? 0.42 : 0.28);
      // Elipse girada hacia atrás para dar profundidad.
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.38);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: rx * 2,
          height: ry * 2,
        ),
        ringStyle,
      );
      canvas.restore();

      // Punto orbital en órbita alrededor de ese anillo.
      final orbitAngle = t * (r.isEven ? 0.5 : -0.38) + r * 2.4;
      final dotX = math.cos(orbitAngle) * rx;
      final dotY = math.sin(orbitAngle) * ry;
      final dotPos = _rotate(Offset(dotX, dotY), -0.38).translate(
        center.dx,
        center.dy,
      );
      canvas.drawCircle(
        dotPos,
        r == 0 ? 2.6 : 2.0,
        Paint()..color = (r == 0 ? nexoraGoldLight : nexoraBlue).withValues(alpha: 0.85),
      );
    }
  }

  Offset _rotate(Offset p, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(p.dx * cos - p.dy * sin, p.dx * sin + p.dy * cos);
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter oldDelegate) =>
      oldDelegate.phase != phase;
}