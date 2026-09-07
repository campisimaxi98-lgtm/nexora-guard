/// Gráficas avanzadas de análisis visual (FASE 7): cuatro vistas animadas
/// — onda (waveform), área, barras y dispersión — todas construidas desde
/// datos REALES del historial ([HistoryRow]). Nada se simula; cada punto es
/// una captura verdadera y las series que la plataforma no expone (p. ej.
/// CPU) se omiten con honestidad.
///
/// Las vistas comparten la animación de entrada: `AnimationController`
/// de ~900 ms con curva easing, de modo que las barras crecen, la onda se
/// "dibuja" y el área se llena — sin tocar los valores subyacentes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../strings.dart';
import '../theme.dart';

/// Tipo de visualización avanzada.
enum NexoraViz { waveform, area, bars, scatter }

extension NexoraVizX on NexoraViz {
  IconData icon() => switch (this) {
    NexoraViz.waveform => Icons.graphic_eq,
    NexoraViz.area => Icons.timeline,
    NexoraViz.bars => Icons.bar_chart,
    NexoraViz.scatter => Icons.scatter_plot,
  };

  String label(AppStrings s) => switch (this) {
    NexoraViz.waveform => s.chartAdvWave,
    NexoraViz.area => s.chartAdvArea,
    NexoraViz.bars => s.chartAdvBars,
    NexoraViz.scatter => s.chartAdvScatter,
  };
}

/// Renders one of the advanced views from real history rows. The active
/// series can be selected; when null the security score is shown.
class NexoraAdvancedChart extends StatefulWidget {
  const NexoraAdvancedChart({
    super.key,
    required this.rows,
    required this.values,
    required this.color,
    required this.viz,
    this.debugLabel,
  });

  /// Historial (para ejes temporales y ventana); puede estar vacío.
  final List<HistoryRow> rows;

  /// Serie de valores reales a dibujar (1:1 con `rows`, tolera null).
  final List<double?> values;

  final Color color;
  final NexoraViz viz;

  /// Etiqueta opcional que se pinta como snipper arriba (solo debug/tests).
  final String? debugLabel;

  @override
  State<NexoraAdvancedChart> createState() => _NexoraAdvancedChartState();
}

class _NexoraAdvancedChartState extends State<NexoraAdvancedChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant NexoraAdvancedChart old) {
    super.didUpdateWidget(old);
    if (old.values != widget.values || old.viz != widget.viz) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.8) ?? nexoraBlue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.debugLabel != null) ...[
          Text(
            widget.debugLabel!,
            style: const TextStyle(fontSize: 11, color: nexoraGoldLight),
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: 96,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _AdvancedPainter(
                values: widget.values,
                color: widget.color,
                viz: widget.viz,
                progress: _t.value,
                labelColor: labelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pinta una de las cuatro vistas usando [progress] (0..1) para animar la
/// entrada. La escala Y toma el rango de la serie real más un margen.
class _AdvancedPainter extends CustomPainter {
  _AdvancedPainter({
    required this.values,
    required this.color,
    required this.viz,
    required this.progress,
    required this.labelColor,
  });

  final List<double?> values;
  final Color color;
  final NexoraViz viz;
  final double progress;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;
    final usable = values.where((v) => v != null).cast<double>().toList();
    if (usable.isEmpty) return;

    final minV = usable.reduce(math.min);
    final maxV = usable.reduce(math.max);
    final spanV = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    // Margen arriba/abajo para que el mínimo y el máximo no toquen los bordes.
    final topPad = size.height * 0.12;
    final bottomPad = size.height * 0.08;
    final chartH = size.height - topPad - bottomPad;
    double yFor(double v) =>
        topPad + chartH - ((v - minV) / spanV) * chartH;

    final n = values.length;
    final step = size.width / (n <= 1 ? 1 : (n - 1));

    switch (viz) {
      case NexoraViz.scatter:
        _paintScatter(canvas, size, step, yFor);
      case NexoraViz.bars:
        _paintBars(canvas, size, step, yFor);
      case NexoraViz.waveform:
      case NexoraViz.area:
        _paintLineAndArea(canvas, size, step, yFor);
    }
  }

  void _paintScatter(Canvas canvas, Size size, double step, double Function(double) yFor) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final visible = i / math.max(1, values.length - 1);
      if (visible > progress) continue;
      final x = i * step;
      final y = yFor(v);
      canvas.drawCircle(Offset(x, y), 3.2, paint);
    }
  }

  void _paintBars(Canvas canvas, Size size, double step, double Function(double) yFor) {
    final barW = math.max(2.0, step * 0.55);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final visible = i / math.max(1, values.length - 1);
      if (visible > progress) continue;
      final x = i * step;
      final yTop = yFor(v);
      final h = (size.height - yTop).clamp(0.0, size.height);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barW / 2, yTop, barW, h),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  void _paintLineAndArea(Canvas canvas, Size size, double step, double Function(double) yFor) {
    // Cuántos puntos quedan visibles según el progreso (efecto "dibujado").
    final countVisible =
        (progress * (values.length - 1)).floor().clamp(0, values.length - 1);

    final linePath = Path();
    final areaPath = Path();
    var started = false;
    for (var i = 0; i <= countVisible && i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = i * step;
      final y = yFor(v);
      if (!started) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
        started = true;
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    if (!started) return;

    if (viz == NexoraViz.area) {
      final lastIdx = countVisible.clamp(0, values.length - 1);
      final lx = lastIdx * step;
      areaPath.lineTo(lx, size.height);
      areaPath.close();
      canvas.drawPath(
        areaPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Punto final actual (interpolado suavemente si se está dibujando).
    final lastIdx = countVisible.clamp(0, values.length - 1);
    final lv = values[lastIdx];
    final lx = lastIdx * step;
    if (lv != null) {
      canvas.drawCircle(
        Offset(lx, yFor(lv)),
        3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedPainter old) =>
      old.values != values ||
      old.color != color ||
      old.viz != viz ||
      old.progress != progress;
}
