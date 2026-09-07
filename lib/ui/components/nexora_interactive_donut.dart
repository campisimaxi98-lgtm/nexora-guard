/// Dona interactiva de estado (FASE 4): segmentos tocables que navegan a
/// pantallas reales. Cada segmento sale de datos reales del snapshot y
/// siempre lleva texto + color (regla de casa: nunca solo visual).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'nexora_cards.dart';
import 'nexora_tokens.dart';

/// Un segmento de la dona + su navegación y su valor honesto.
class NxDonutSegment {
  const NxDonutSegment({
    required this.id,
    required this.label,
    required this.color,
    required this.ratio,
    required this.subtitle,
    required this.onTap,
  });

  final String id;
  final String label;
  final Color color;

  /// 0..1 — la fracción del anillo.
  final double ratio;

  final String subtitle;
  final VoidCallback onTap;
}

class NexoraDonut extends StatelessWidget {
  const NexoraDonut({
    super.key,
    required this.segments,
    required this.strings,
    this.title,
    this.centerPercent,
    this.centerColor,
    this.onCenterTap,
  });

  final List<NxDonutSegment> segments;
  final AppStrings strings;
  final String? title;

  /// Valor central personalizado (0..100). Si se omite, se usa la suma de
  /// las proporciones de los segmentos (FASE 4).
  final double? centerPercent;

  /// Color del porcentaje central: la salud agregada se pinta por nivel
  /// (verde → ámbar → naranja → rojo) y el tap explica la escala (FASE 8).
  final Color? centerColor;

  /// Tap sobre el círculo central: abre la escala de colores.
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    final ratio = segments.fold(0.0, (a, b) => a + b.ratio);
    final centerValue = centerPercent ??
        (ratio.clamp(0.0, 1.0) * 100).round().toDouble();

    return NexoraCard(
      glow: true,
      child: Padding(
        padding: const EdgeInsets.all(ntPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderRow(
              icon: Icons.donut_large,
              title: title ?? strings.donutStatusTitle,
              iconColor: nexoraGoldLight,
            ),
            const SizedBox(height: ntGap),
            SizedBox(
              height: 132,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) {
                            final local = d.localPosition;
                            final adj = Offset(
                              local.dx - 66,
                              local.dy - 66,
                            );
                            if (adj.distance < 20) return;
                            var angle = math.atan2(adj.dy, adj.dx) + math.pi / 2;
                            if (angle < 0) angle += math.pi * 2;
                            final total = segments.fold(
                              0.0,
                              (a, b) => a + b.ratio,
                            );
                            if (total <= 0) return;
                            var acc = 0.0;
                            for (final seg in segments) {
                              acc += seg.ratio;
                              if (angle <= (acc / total) * math.pi * 2) {
                                seg.onTap();
                                return;
                              }
                            }
                          },
                          child: CustomPaint(
                            painter: _DonutPainter(segments: segments),
                          ),
                        ),
                        // El centro solo muestra el porcentaje de salud
                        // (FASE 8) y redirige su tap a la escala de colores.
                        // Cubre únicamente el disco central (~40 px), nunca
                        // el anillo: los arcos siguen navegando.
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onCenterTap,
                            child: SizedBox.square(
                              dimension: 80,
                              child: Center(
                                child: Text(
                                  '${centerValue.round()}%',
                                  key: const Key('nx_donut_center'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: centerColor ?? nexoraGoldLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ntGap),
                  Expanded(
                    child: Column(
                      children: [
                        for (final seg in segments)
                          _LegendRow(
                            color: seg.color,
                            label: seg.label,
                            value: seg.subtitle,
                            onTap: seg.onTap,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.85);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ntRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 11.5, color: subColor)),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

/// Pinta el anillo segmentado con huecos pequeños entre segmentos.
class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<NxDonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 4;
    final stroke = outer * 0.30;
    final rect = Rect.fromCircle(center: center, radius: outer - stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = nexoraBorder.withValues(alpha: 0.6);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    const gap = 0.04;
    var start = -math.pi / 2;
    final total = segments.fold(0.0, (a, b) => a + b.ratio);
    if (total <= 0) return;
    for (final seg in segments) {
      final sweep = math.max(0.0, (seg.ratio / total) * math.pi * 2 - gap);
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = seg.color,
      );
      start += (seg.ratio / total) * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}