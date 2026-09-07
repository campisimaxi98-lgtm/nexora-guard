/// Análisis/Gráficas (FASE 7): series reales del historial en línea de
/// tiempo (temperatura, memoria, almacenamiento, puntaje), dona de
/// almacenamiento actual y consumo por app de las últimas 24 h.
///
/// Todas las cifras vienen del snapshot y del historial ya persistidos por
/// [CaptureService]: nada se simula. Si no hay historial o la plataforma no
/// expone el dato, se dice con honestidad.
library;

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../../core/models.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';

class NexoraChartsScreen extends StatelessWidget {
  const NexoraChartsScreen({
    super.key,
    required this.snapshot,
    required this.history,
    required this.strings,
    this.onRefresh,
    this.extraTrailing,
  });

  final Snapshot snapshot;
  final List<HistoryRow> history;
  final AppStrings strings;
  final Future<void> Function()? onRefresh;
  final Widget? extraTrailing;

  @override
  Widget build(BuildContext context) {
    final rows = (history.length > 24 ? history.sublist(history.length - 24) : history)
        .toList();
    final reversed = rows.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(ntPad),
      children: [
        NexoraCard(
          child: Row(
            children: [
              const Icon(Icons.show_chart, color: nexoraGoldLight, size: 18),
              const SizedBox(width: ntGapSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.chartTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      strings.chartLastSeconds(reversed.length),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: strings.chartRefresh,
                ),
              ?extraTrailing,
            ],
          ),
        ),
        const SizedBox(height: ntPadSmall),

        if (reversed.isEmpty)
          NexoraCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: nexoraBlue, size: 18),
                  const SizedBox(width: ntGapSmall),
                  Expanded(
                    child: Text(strings.chartNoHistory),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _ChartCard(
            title: strings.chartBatteryTemp,
            color: nexoraRed,
            chart: _LineChart(
              values: reversed
                  .map((r) => r.batteryTempC.toDouble())
                  .toList(),
              maskNull: true,
              color: nexoraRed,
            ),
            legend: _celsiusLegend(snapshot, reversed),
          ),
          _ChartCard(
            title: strings.chartMemory,
            color: nexoraBlue,
            chart: _LineChart(
              values: reversed.map((r) => r.memAvailablePct.toDouble()).toList(),
              color: nexoraBlue,
            ),
            legend: _pctLegend(snapshot.memory.availableBytes, snapshot.memory.totalBytes),
          ),
          _ChartCard(
            title: strings.chartStorage,
            color: nexoraGold,
            chart: _LineChart(
              values: reversed
                  .map((r) => r.storageFreePct.toDouble())
                  .toList(),
              color: nexoraGold,
            ),
            legend: _pctLegend(snapshot.storage.freeBytes, snapshot.storage.totalBytes),
          ),
          _ChartCard(
            title: strings.chartScore,
            color: nexoraGoldLight,
            chart: _LineChart(
              values: reversed.map((r) => r.score.toDouble()).toList(),
              color: nexoraGoldLight,
            ),
            legend: Text('${reversed.last.score}'),
          ),
        ],

        const SizedBox(height: ntPadSmall),
        _AdvancedAnalysisCard(rows: reversed, strings: strings),
        const SizedBox(height: ntPadSmall),
        _StorageDonutCard(
          storage: snapshot.storage,
          strings: strings,
        ),
        const SizedBox(height: ntPadSmall),
        _UsageCard(apps: snapshot.apps, strings: strings),
      ],
    );
  }

  Widget _celsiusLegend(Snapshot snapshot, List<HistoryRow> rows) {
    final last = rows.isEmpty ? null : rows.last.batteryTempC;
    if (last != null && last >= 0) return Text('$last${strings.chartUnitCelsius}');
    if (snapshot.battery.temperatureAvailable) {
      return Text(
        '${snapshot.battery.temperatureCelsius.toStringAsFixed(1)}${strings.chartUnitCelsius}',
      );
    }
    return Text('—');
  }

  Widget _pctLegend(int part, int total) {
    final pct = total > 0 ? (part * 100 / total).round() : 0;
    return Text('$pct %');
  }
}

/// Tarjeta de una serie con su leyenda e historieta.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.color,
    required this.chart,
    required this.legend,
  });

  final String title;
  final Color color;
  final Widget chart;
  final Widget legend;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ntGapSmall),
    child: NexoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 16, color: nexoraGoldLight),
              const SizedBox(width: ntGapSmall),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              legend,
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 96, child: chart),
        ],
      ),
    ),
  );
}

/// Gráfico de líneas con relleno degradado. `maskNull` omite puntos -1
/// (valores que la plataforma no expone, p. ej. temperatura en iOS).
class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.values,
    required this.color,
    this.maskNull = false,
  });

  final List<double> values;
  final Color color;
  final bool maskNull;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _LineChartPainter(
      values: values,
      color: color,
      maskNull: maskNull,
      gridColor: nexoraBorder.withValues(alpha: 0.5),
    ),
  );
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.maskNull,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final bool maskNull;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Grid horizontal (0%, 50%, 100%).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = h - h * f;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final usable = values.where((v) => !(maskNull && v < 0)).toList();
    if (usable.isEmpty) return;

    double yFor(double v) => h - (v.clamp(0, 100) / 100) * (h - 6) - 3;
    final step = w / (values.isEmpty ? 1 : values.length);

    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Polilínea con huecos para valores nulos.
    Path? path;
    Path? fillPath;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (maskNull && v < 0) {
        path = null;
        fillPath = null;
        continue;
      }
      final x = i * step;
      final y = yFor(v);
      if (path == null) {
        path = Path()..moveTo(x, y);
        fillPath = Path()..moveTo(x, h)..lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath!.lineTo(x, y);
      }
    }
    path ??= Path();
    fillPath ??= Path();
    fillPath.lineTo((values.length - 1) * step, h);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    // Punto del último valor disponible.
    if (usable.isNotEmpty) {
      final lastIdx = values.lastIndexWhere((v) => !(maskNull && v < 0));
      final last = values[lastIdx];
      canvas.drawCircle(
        Offset(lastIdx * step, yFor(last)),
        3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values ||
      old.color != color ||
      old.maskNull != maskNull;
}

/// Dona del almacenamiento ACTUAL: usa los bytes reales del snapshot.
class _StorageDonutCard extends StatelessWidget {
  const _StorageDonutCard({required this.storage, required this.strings});

  final StorageInfo storage;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => NexoraCard(
    glow: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(
          icon: Icons.storage,
          title: strings.chartStorageNow,
        ),
        const SizedBox(height: ntGapSmall),
        Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _DonutPainter(
                  usedRatio: 1 - storage.freeRatio,
                  usedColor: nexoraGoldLight,
                  freeColor: nexoraBorder,
                ),
                child: Center(
                  child: Text(
                    '${(storage.freeRatio * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ntPad),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueRow(
                    icon: Icons.check_circle_outline,
                    label: strings.chartStorageFree,
                    value: _gb(storage.freeBytes),
                    color: severityGreen,
                  ),
                  const SizedBox(height: 8),
                  ValueRow(
                    icon: Icons.cleaning_services_outlined,
                    label: strings.chartStorageCache,
                    value: _gb(storage.appCacheBytes),
                    color: nexoraOrange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  String _gb(int bytes) => '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Análisis avanzado (FASE 7): elige una serie real y la ves como onda,
/// área, barras o dispersión — todas animadas y con los datos del historial.
class _AdvancedAnalysisCard extends StatefulWidget {
  const _AdvancedAnalysisCard({required this.rows, required this.strings});

  final List<HistoryRow> rows;
  final AppStrings strings;

  @override
  State<_AdvancedAnalysisCard> createState() => _AdvancedAnalysisCardState();
}

class _AdvancedAnalysisCardState extends State<_AdvancedAnalysisCard> {
  // Series seleccionables según la disponibilidad real en el historial.
  late final List<_SeriesDef> _options = _buildOptions();

  String _selected = '_default';

  List<_SeriesDef> _buildOptions() {
    final s = widget.strings;
    final defs = <_SeriesDef>[
      _SeriesDef('_default', s.chartAdvScore, nexoraGoldLight, (r) => r.score.toDouble()),
    ];
    final hasCpu = widget.rows.any((r) => r.cpuPercentAvailable);
    if (hasCpu) {
      defs.add(_SeriesDef('cpu', s.chartSeriesCpu, nexoraWine, (r) => r.cpuUsedPercent.toDouble()));
    }
    defs.add(_SeriesDef('mem', s.chartSeriesMemory, nexoraBlue, (r) => r.memAvailablePct.toDouble()));
    defs.add(_SeriesDef('storage', s.chartSeriesStorage, severityGreen, (r) => r.storageFreePct.toDouble()));
    defs.add(_SeriesDef('apps', s.chartSeriesApps, nexoraOrange, (r) => r.riskyApps.toDouble()));
    final hasTemp = widget.rows.any((r) => r.batteryTempC >= 0);
    if (hasTemp) {
      defs.add(_SeriesDef('temp', s.chartSeriesTemp, nexoraRed, (r) => r.batteryTempC.toDouble()));
    }
    return defs;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.length < 2) {
      return NexoraCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: ntPadSmall),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: nexoraBlue, size: 18),
              const SizedBox(width: ntGapSmall),
              Expanded(child: Text(widget.strings.chartAdvNeedsHistory)),
            ],
          ),
        ),
      );
    }

    final active = _options.firstWhere(
      (o) => o.id == _selected,
      orElse: () => _options.first,
    );
    final values = widget.rows.map(active.extract).toList();

    return NexoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(icon: Icons.blur_linear, title: widget.strings.chartAdvTitle),
          const SizedBox(height: ntGapSmall),
          // Selector de serie (datos reales disponibles).
          DropdownButtonFormField<String>(
            initialValue: _selected,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.tune, size: 18),
            ),
            items: [
              for (final o in _options)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(o.label, style: const TextStyle(fontSize: 13)),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selected = v);
            },
          ),
          const SizedBox(height: ntGapSmall),
          for (final viz in NexoraViz.values) ...[
            _VizRow(
              kind: viz,
              strings: widget.strings,
              widget: NexoraAdvancedChart(
                rows: widget.rows,
                values: values,
                color: active.color,
                viz: viz,
              ),
            ),
            const SizedBox(height: ntGapSmall),
          ],
        ],
      ),
    );
  }
}

class _SeriesDef {
  const _SeriesDef(this.id, this.label, this.color, this.extract);
  final String id;
  final String label;
  final Color color;
  final double? Function(HistoryRow) extract;
}

class _VizRow extends StatelessWidget {
  const _VizRow({
    required this.kind,
    required this.strings,
    required this.widget,
  });
  final NexoraViz kind;
  final AppStrings strings;
  final Widget widget;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(kind.icon(), size: 14, color: nexoraGoldLight),
          const SizedBox(width: 6),
          Text(
            kind.label(strings),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 6),
      widget,
    ],
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.usedRatio,
    required this.usedColor,
    required this.freeColor,
  });

  final double usedRatio;
  final Color usedColor;
  final Color freeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    stroke.color = freeColor;
    canvas.drawArc(rect.deflate(6), 0, 2 * 3.14159, false, stroke);
    stroke.color = usedColor;
    canvas.drawArc(
      rect.deflate(6),
      -3.14159 / 2,
      2 * 3.14159 * usedRatio.clamp(0, 1),
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.usedRatio != usedRatio || old.usedColor != usedColor;
}

/// Consumo por app: datos reales de las últimas 24 h (bytes o tiempo en
/// pantalla). Si nada está disponible, se dice vacío con honestidad.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.apps, required this.strings});

  final List<AppRisk> apps;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final rows = <(AppRisk, String)>[];
    for (final a in apps) {
      final rx = a.rxBytes24h;
      final tx = a.txBytes24h;
      final fg = a.foregroundMillis24h;
      if (rx >= 0 && tx >= 0 && (rx > 0 || tx > 0)) {
        final total = rx + tx;
        rows.add((
          a,
          '${_mb(total)} MB · ${strings.chartUsageDownload} ${_mb(rx)} / '
              '${strings.chartUsageUpload} ${_mb(tx)}',
        ));
        continue;
      }
      if (fg > 0) {
        rows.add((a, '${_minutes(fg)} min ${strings.chartUsageScreen}'));
      }
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));

    return NexoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(
            icon: Icons.data_usage,
            title: strings.chartUsageTitle,
          ),
          const SizedBox(height: 4),
          if (rows.isEmpty)
            Text(
              strings.chartUsageEmpty,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).disabledColor,
              ),
            )
          else
            for (final (app, label) in rows.take(6)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(0);
  String _minutes(int millis) => (millis / 60000).round().toString();
}