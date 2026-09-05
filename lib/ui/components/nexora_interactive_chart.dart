/// Gráfica central interactiva de la evolución (FASE 4).
///
/// Una sola gráfica línea para todas las métricas del historial sellado.
/// Nada se simula: cada serie sale de [HistoryRow] (datos reales); si una
/// métrica no la expone la plataforma (p. ej. la carga de CPU todavía) la
/// serie aparece en el conmutador como DESHABILITADA con su motivo, nunca
/// como un número inventado.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../strings.dart';
import '../theme.dart';
import 'nexora_tokens.dart';

/// Ventana de tiempo del gráfico.
enum NxChartWindow {
  h1(Duration(hours: 1)),
  h6(Duration(hours: 6)),
  h24(Duration(hours: 24)),
  d7(Duration(days: 7));

  const NxChartWindow(this.duration);
  final Duration duration;

  String label(AppStrings s) => switch (this) {
    NxChartWindow.h1 => s.chartWin1h,
    NxChartWindow.h6 => s.chartWin6h,
    NxChartWindow.h24 => s.chartWin24h,
    NxChartWindow.d7 => s.chartWin7d,
  };
}

/// Métrica graficable (extraída de una fila real del historial).
class NxChartSeries {
  const NxChartSeries({
    required this.id,
    required this.label,
    required this.color,
    required this.extract,
    required this.format,
    this.available = true,
  });

  final String id;
  final String label;
  final Color color;

  /// Valor absoluto de la serie; `null` = sin dato en esa captura.
  final double? Function(HistoryRow row) extract;

  /// Formatea el valor absoluto para el tooltip y los ejes.
  final String Function(double value) format;

  /// `false` = métrica que la plataforma no expone (CPU hoy): aparece
  /// deshabilitada y se explica por qué, sin números falsos.
  final bool available;
}

class NexoraInteractiveChart extends StatefulWidget {
  const NexoraInteractiveChart({
    super.key,
    required this.rows,
    required this.strings,
  });

  final List<HistoryRow> rows;
  final AppStrings strings;

  @override
  State<NexoraInteractiveChart> createState() => _NexoraInteractiveChartState();
}

class _NexoraInteractiveChartState extends State<NexoraInteractiveChart> {
  NxChartWindow _window = NxChartWindow.h24;
  String? _seriesId; // null = todas

  List<HistoryRow> get _windowed {
    final now = widget.rows.isEmpty
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(widget.rows.first.timestampMillis);
    final from = now.subtract(_window.duration);
    final cut = from.millisecondsSinceEpoch;
    return widget.rows
        .where((r) => r.timestampMillis >= cut)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final rows = _windowed;
    final series = _buildSeries(widget.strings,
        cpuAvailable: widget.rows.any((r) => r.cpuPercentAvailable));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: ntGapSmall,
          runSpacing: ntGapSmall,
          children: [
            for (final w in NxChartWindow.values)
              _WindowChip(
                label: w.label(s),
                selected: _window == w,
                onTap: () => setState(() => _window = w),
              ),
          ],
        ),
        const SizedBox(height: ntGapSmall),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final ser in [null, ...series.where((x) => x.available)])
                _seriesChip(ser, series, s),
            ],
          ),
        ),
        if (rows.isNotEmpty && !series.any((x) => x.id == 'cpu' && x.available)) ...[
          const SizedBox(height: ntGapSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: nexoraBlue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.chartCpuUnavailable,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: ntGapSmall),
        SizedBox(
          height: 210,
          width: double.infinity,
          child: rows.length < 2
              ? Center(
                  child: Text(s.chartNoData, style: Theme.of(context).textTheme.bodySmall),
                )
              : RepaintBoundary(
                  child: _ChartCanvas(
                    rows: rows,
                    series: series,
                    activeId: _seriesId,
                    strings: s,
                  ),
                ),
        ),
        const SizedBox(height: ntGapSmall),
        Align(
          alignment: Alignment.center,
          child: Text(
            s.chartTapHint,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _seriesChip(NxChartSeries? ser, List<NxChartSeries> all, AppStrings s) {
    final selected = (ser == null && _seriesId == null) || (ser != null && _seriesId == ser.id);
    final color = ser?.color ?? nexoraGoldLight;
    return Padding(
      padding: const EdgeInsets.only(right: ntGapSmall),
      child: InkWell(
        onTap: () => setState(() => _seriesId = ser?.id),
        borderRadius: BorderRadius.circular(ntRadiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: ntPadSmall, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : nexoraSurfaceRaised,
            borderRadius: BorderRadius.circular(ntRadiusPill),
            border: Border.all(
              color: selected ? color : nexoraBorder,
            ),
          ),
          child: Row(
            children: [
              if (ser != null) ...[
                Icon(Icons.circle, size: 9, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                ser?.label ?? s.chartSeriesAll,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<NxChartSeries> _buildSeries(AppStrings s, {bool cpuAvailable = false}) => [
  NxChartSeries(
    id: 'security',
    label: s.chartSeriesSecurity,
    color: nexoraGold,
    extract: (r) => (100 - r.score).clamp(0, 100).toDouble(),
    format: (v) => '${v.round()}${s.chartUnitPct}',
  ),
  NxChartSeries(
    id: 'memory',
    label: s.chartSeriesMemory,
    color: nexoraBlue,
    extract: (r) => r.memAvailablePct.toDouble(),
    format: (v) => '${v.round()}${s.chartUnitPct}',
  ),
  NxChartSeries(
    id: 'storage',
    label: s.chartSeriesStorage,
    color: severityGreen,
    extract: (r) => r.storageFreePct.toDouble(),
    format: (v) => '${v.round()}${s.chartUnitPct}',
  ),
  NxChartSeries(
    id: 'apps',
    label: s.chartSeriesApps,
    color: nexoraOrange,
    extract: (r) => r.riskyApps.toDouble(),
    format: (v) => '${v.round()} ${s.chartUnitApps}',
  ),
  NxChartSeries(
    id: 'temp',
    label: s.chartSeriesTemp,
    color: nexoraGoldLight,
    extract: (r) => r.batteryTempC >= 0 ? r.batteryTempC.toDouble() : null,
    format: (v) => '${v.round()}${s.chartUnitTemp}',
  ),
  NxChartSeries(
    id: 'cpu',
    label: s.chartSeriesCpu,
    color: nexoraWine,
    extract: (r) => r.cpuPercentAvailable ? r.cpuUsedPercent.toDouble() : null,
    format: (v) => '${v.round()}${s.chartUnitPct}',
    available: cpuAvailable,
  ),
];

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(ntRadiusPill),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? nexoraSurfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(ntRadiusPill),
        border: Border.all(color: selected ? nexoraGold : nexoraBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: selected ? nexoraGoldLight : null,
        ),
      ),
    ),
  );
}

class _ChartCanvas extends StatefulWidget {
  const _ChartCanvas({
    required this.rows,
    required this.series,
    required this.activeId,
    required this.strings,
  });

  final List<HistoryRow> rows;
  final List<NxChartSeries> series;
  final String? activeId;
  final AppStrings strings;

  @override
  State<_ChartCanvas> createState() => _ChartCanvasState();
}

class _ChartCanvasState extends State<_ChartCanvas> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = _ChartPainter(
          rows: widget.rows,
          series: widget.series,
          activeId: widget.activeId,
          strings: widget.strings,
          size: constraints.biggest,
          hover: _hover,
          labelColor: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withValues(alpha: 0.8) ?? nexoraBlue,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setState(() {
            _hover = painter.pointAt(d.localPosition.dx);
          }),
          onTapUp: (_) => setState(() => _hover = null),
          onTapCancel: () => setState(() => _hover = null),
          child: CustomPaint(
            size: Size.infinite,
            painter: painter,
          ),
        );
      },
    );
  }
}

/// Pinta la gráfica: grilla, series y tooltip del punto tocado.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.rows,
    required this.series,
    required this.activeId,
    required this.strings,
    required this.size,
    required this.hover,
    required this.labelColor,
  });

  final List<HistoryRow> rows;
  final List<NxChartSeries> series;
  final String? activeId;
  final AppStrings strings;
  final Size size;
  final int? hover;
  final Color labelColor;

  static const _padL = 8.0;
  static const _padR = 10.0;
  static const _padT = 12.0;
  static const _padB = 24.0;

  Rect get _chart => Rect.fromLTRB(
    _padL,
    _padT,
    size.width - _padR,
    size.height - _padB,
  );

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final chart = _chart;
    if (chart.width <= 1 || chart.height <= 1) return;

    final activeId = this.activeId;
    NxChartSeries? active;
    if (activeId != null) {
      for (final s in series) {
        if (s.id == activeId) {
          active = s;
          break;
        }
      }
    }
    final shown = active != null ? [active] : series;

    final now = DateTime.fromMillisecondsSinceEpoch(rows.first.timestampMillis);
    final t0 = DateTime.fromMillisecondsSinceEpoch(rows.last.timestampMillis);
    final spanMs = math.max(1.0, (now.millisecondsSinceEpoch - t0.millisecondsSinceEpoch).toDouble());

    double xOf(int ts) =>
        chart.left +
        (now.millisecondsSinceEpoch - ts).toDouble() / spanMs * chart.width;

    final maxApps = rows
        .map((r) => r.riskyApps)
        .fold<int>(0, math.max);

    // Máximo real de la serie única (para etiquetas y escala honestas).
    double? singleMax;
    if (active != null) {
      final vals = <double>[];
      for (final r in rows) {
        final raw = active.extract(r);
        if (raw != null) vals.add(raw);
      }
      if (active.id == 'security' ||
          active.id == 'memory' ||
          active.id == 'storage') {
        singleMax = 100.0;
      } else {
        singleMax = vals.isEmpty ? 1.0 : vals.reduce(math.max);
        if (singleMax <= 0) singleMax = 1.0;
      }
    }

    for (final s in shown) {
      final points = <Offset>[];
      for (final r in rows) {
        final raw = s.extract(r);
        if (raw == null) continue;
        final double v;
        if (activeId == null) {
          v = switch (s.id) {
            'security' || 'memory' || 'storage' => raw,
            'apps' => maxApps > 0 ? raw / maxApps * 100 : 0.0,
            'temp' => raw / 45 * 100,
            _ => raw,
          }.clamp(0.0, 100.0).toDouble();
        } else {
          v = raw;
        }
        final maxV = activeId == null ? 100.0 : singleMax!;
        final y = chart.bottom - v / maxV * chart.height;
        points.add(Offset(xOf(r.timestampMillis), y));
      }
      if (points.isEmpty) continue;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = activeId == null ? 1.6 : 2.2
          ..strokeCap = StrokeCap.round
          ..color = s.color.withValues(alpha: activeId == null ? 0.85 : 1),
      );
      if (activeId != null) {
        final area = Path.from(path)..lineTo(points.last.dx, chart.bottom)..lineTo(
          points.first.dx,
          chart.bottom,
        )..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.16),
                s.color.withValues(alpha: 0.0),
              ],
            ).createShader(chart),
        );
      }
    }

    // Grilla horizontal + etiquetas del eje izquierdo.
    final grid = Paint()
      ..color = nexoraBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 9.5, color: labelColor);
    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      final label = activeId == null
          ? '${(100 - i * 25)}${strings.chartUnitPct}'
          : active!.format(((singleMax ?? 100) * (1 - i / 4)).clamp(0.0, double.infinity));
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chart.left - _padL + 2, y - tp.height - 1));
    }

    // Primer y último momento en el eje X.
    final axisX = TextPainter(
      text: TextSpan(
        text: '${_fmtTime(t0)}  ·  ${_fmtTime(now)}',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    axisX.paint(canvas, Offset(chart.left, chart.bottom + 4));

    // Punto tocado: crosshair + tooltip.
    final hover = this.hover;
    if (hover != null && hover >= 0 && hover < rows.length) {
      final row = rows[hover];
      final x = xOf(row.timestampMillis);
      canvas.drawLine(
        Offset(x, chart.top),
        Offset(x, chart.bottom),
        Paint()
          ..color = nexoraGoldLight.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      _drawTooltip(canvas, chart, row, x, active);
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Rect chart,
    HistoryRow row,
    double x,
    NxChartSeries? active,
  ) {
    final time = _fmtTime(DateTime.fromMillisecondsSinceEpoch(row.timestampMillis));
    final lines = <(String, {bool bold})>[];
    if (active != null) {
      lines.add((time, bold: true));
      lines.add((active.label, bold: true));
      lines.add((active.format(active.extract(row) ?? 0), bold: false));
    } else {
      lines.add((time, bold: true));
      for (final s in series) {
        final raw = s.extract(row);
        if (raw != null) lines.add(('${s.label}  ${s.format(raw)}', bold: false));
      }
    }

    final tp = TextPainter(
      text: TextSpan(
        style: TextStyle(fontSize: 10.5, color: labelColor),
        children: [
          for (final (idx, l) in lines.indexed)
            TextSpan(
              text: l.$1 + (idx == lines.length - 1 ? '' : '\n'),
              style: l.bold
                  ? const TextStyle(fontWeight: FontWeight.w800, color: nexoraGoldLight)
                  : null,
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: chart.width * 0.55);

    const pad = 8.0;
    var left = x - tp.width / 2 - pad / 2;
    left = left.clamp(chart.left, chart.right - tp.width - pad * 2);
    final top = chart.top;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, tp.width + pad * 2, tp.height + pad),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = nexoraSurfaceRaised.withValues(alpha: 0.96));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = nexoraBorder,
    );
    tp.paint(canvas, Offset(left + pad, top + pad / 2));
  }

  String _fmtTime(DateTime dt) => (dt.isAfter(DateTime.now().subtract(const Duration(days: 2))))
      ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
      : '${dt.day}/${dt.month}';

  int? pointAt(double dx) {
    if (rows.isEmpty) return 0;
    final now = DateTime.fromMillisecondsSinceEpoch(rows.first.timestampMillis);
    final t0 = DateTime.fromMillisecondsSinceEpoch(rows.last.timestampMillis);
    final span = math.max(
      1.0,
      (now.millisecondsSinceEpoch - t0.millisecondsSinceEpoch).toDouble(),
    );
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < rows.length; i++) {
      final x = _chart.left +
          (now.millisecondsSinceEpoch - rows[i].timestampMillis).toDouble() / span * _chart.width;
      final d = (x - dx).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.rows != rows ||
      old.series != series ||
      old.activeId != activeId ||
      old.size != size ||
      old.hover != hover;
}