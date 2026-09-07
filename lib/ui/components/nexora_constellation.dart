/// Fondo animado de constelación — HOME de NEXORA GUARD (FASE 7).
///
/// Sustituye al planeta en la portada: estrellas de varios tamaños con
/// líneas que las unen (estilo constelación), partículas en rojo/amarillo/
/// blanco-gris con deriva lenta y un parallax ligero entre capas. Todo
/// dibujado con `CustomPainter` (cero assets, cero dependencias) y
/// posiciones DETERMINISTAS (seeded una vez por clase) para que el dibujo
/// sea estable entre frames y en tests: lo único que varía es `phase`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class NexoraConstellation extends StatefulWidget {
  const NexoraConstellation({super.key, this.slow = true});

  /// `true` anima la deriva; `false` congela el dibujo (ahorro en pantallas
  /// que no necesitan movimiento perpetuo).
  final bool slow;

  @override
  State<NexoraConstellation> createState() => _NexoraConstellationState();
}

class _NexoraConstellationState extends State<NexoraConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 52000),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = CustomPaint(
      painter: _ConstellationPainter(phase: 0),
      size: Size.infinite,
    );
    if (!widget.slow) return RepaintBoundary(child: core);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) => CustomPaint(
          painter: _ConstellationPainter(phase: _drift.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Estrella fija y partícula derivan de un Random con seed fijo: mismas
/// posiciones en cada frame / ejecución (también para los goldens).
class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({required this.phase});

  /// 0..1 dentro del ciclo de 52 s.
  final double phase;

  static final math.Random _seed = math.Random(0x4E4558);

  /// Estrellas: (x, y, radio, capa 0=fondo/1=frente, semilla).
  static final List<(double, double, double, int, int)> _stars = () {
    final list = <(double, double, double, int, int)>[];
    // Fondo: 90 estrellas pequeñas y tenues.
    for (var i = 0; i < 90; i++) {
      list.add((
        _seed.nextDouble(),
        _seed.nextDouble(),
        0.5 + _seed.nextDouble() * 0.4,
        0,
        i,
      ));
    }
    // Frente: 34 estrellas más visibles y de tamaños variados.
    for (var i = 0; i < 34; i++) {
      list.add((
        _seed.nextDouble(),
        _seed.nextDouble(),
        0.7 + _seed.nextDouble() * 1.4,
        1,
        i + 900,
      ));
    }
    return list;
  }();

  /// Pares (índices de [_stars] de la capa frontal) que se conectan como
  /// constelación. Índice real = 90 + índice de la lista frontal.
  static const _constellations = <(int, int, double)>[
    (0, 1, 0.5), (1, 5, 0.5), (5, 6, 0.42), (6, 12, 0.38),
    (0, 3, 0.45), (3, 9, 0.45), (9, 4, 0.42), (4, 8, 0.4),
    (7, 15, 0.45), (15, 16, 0.5), (16, 10, 0.42), (10, 21, 0.4),
    (2, 11, 0.45), (11, 17, 0.4), (17, 22, 0.42), (22, 13, 0.38),
    (14, 19, 0.5), (19, 24, 0.45), (24, 18, 0.4), (20, 23, 0.45),
    (23, 25, 0.42), (25, 26, 0.4), (27, 28, 0.45), (28, 29, 0.5),
    (30, 31, 0.42), (12, 8, 0.35), (16, 21, 0.35), (6, 11, 0.32),
  ];

  /// Partículas: (x0, y0, fase local, radio, paleta 0=rojo 1=amarillo
  /// 2=blanco 3=gris, capa).
  static final List<(double, double, double, double, int, int)> _particles = () {
    final list = <(double, double, double, double, int, int)>[];
    for (var i = 0; i < 30; i++) {
      list.add((
        _seed.nextDouble(),
        _seed.nextDouble(),
        _seed.nextDouble() * 6.28,
        1.0 + _seed.nextDouble() * 1.6,
        i % 4,
        i.isEven ? 1 : 0,
      ));
    }
    return list;
  }();

  static const _palette = <Color>[
    nexoraRed,
    nexoraGold,
    Colors.white,
    Color(0xFFB9C2D0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = phase * 2 * math.pi;

    // ── Líneas de constelación (capa delantera, con parpadeo lento) ──
    for (final (a, b, base) in _constellations) {
      final sa = _stars[90 + a];
      final sb = _stars[90 + b];
      final pulse =
          0.10 + 0.10 * (0.5 + 0.5 * math.sin(t * 0.5 + a * 1.3 + b * 0.7));
      canvas.drawLine(
        Offset(
          w * sa.$1 + _bgDrift(t, sa.$4, 1.0),
          h * sa.$2 + _bgDrift(t, sa.$4, 1.0, vertical: true),
        ),
        Offset(
          w * sb.$1 + _bgDrift(t, sb.$4, 1.0),
          h * sb.$2 + _bgDrift(t, sb.$4, 1.0, vertical: true),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = base * 0.7
          ..strokeCap = StrokeCap.round
          ..color = nexoraBlue.withValues(alpha: base * (0.5 + pulse)),
      );
    }

    // ── Estrellas: fondo (parallax lento) y frente (parallax normal) ──
    for (var i = 0; i < _stars.length; i++) {
      final (sx, sy, r, layer, sid) = _stars[i];
      final speed = layer == 0 ? 0.5 : 1.0;
      final alpha = layer == 0
          ? 0.22 + 0.16 * (0.5 + 0.5 * math.sin(t * 0.4 + sid * 1.37))
          : 0.55 + 0.35 * (0.5 + 0.5 * math.sin(t * 0.7 + sid * 1.71));
      final color = layer == 0
          ? const Color(0xFF9FB2C8)
          : (sid % 5 == 0 ? nexoraGold : Colors.white);
      canvas.drawCircle(
        Offset(
          w * sx + _bgDrift(t, sid, speed),
          h * sy + _bgDrift(t, sid, speed, vertical: true),
        ),
        r,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }

    // ── Partículas rojas / amarillas / blancas en deriva ──
    for (final (px, py, local, r, pal, layer) in _particles) {
      final speed = layer == 0 ? 0.55 : 1.1;
      final orbit = math.sin(t * speed + local);
      final orbitY = math.sin(t * speed * 0.82 + local * 1.3);
      final x = w * px + orbit * w * 0.045 * speed;
      final y = h * py + orbitY * h * 0.045 * speed;
      final hint = 0.35 + 0.45 * (0.5 + 0.5 * math.sin(t * 0.9 + local * 2.1));
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = _palette[pal].withValues(alpha: hint.clamp(0.0, 1.0)),
      );
    }
  }

  /// Deriva de parallax ligera: cada estrella orbita un poco según su semilla.
  double _bgDrift(double t, int seed, double speed, {bool vertical = false}) {
    final offset = vertical ? t * 0.62 : t * 0.5;
    final phaseLocal = offset * speed + seed * 2.399;
    return math.sin(phaseLocal) * 6.0 * speed;
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.phase != phase;
}