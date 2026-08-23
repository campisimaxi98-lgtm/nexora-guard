/// Estadísticas — trae `/api/me/stats` del backend y las muestra con
/// gráficos propios (sin Chart.js ni ningún paquete: `CustomPainter` puro,
/// igual criterio que `nexora_apps_analysis.dart`). Solo tiene sentido en
/// el flavor `connected`, con sesión iniciada.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import '../../core/nexora_api_client.dart';
import '../theme.dart';

class NexoraStatsScreen extends StatefulWidget {
  const NexoraStatsScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.getDocumentsPath,
  });

  final String serverUrl;
  final String token;
  final Future<String?> Function() getDocumentsPath;

  @override
  State<NexoraStatsScreen> createState() => _NexoraStatsScreenState();
}

class _NexoraStatsScreenState extends State<NexoraStatsScreen> {
  late Future<NexoraStats> _future = _load();
  bool _exporting = false;

  NexoraApiClient get _client =>
      NexoraApiClient(baseUrl: widget.serverUrl, token: widget.token);

  Future<NexoraStats> _load() => _client.fetchStats();

  Future<void> _export() async {
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await _client.exportCsv();
      await Clipboard.setData(ClipboardData(text: csv));

      String message = 'Datos copiados al portapapeles.';
      try {
        final dir = await widget.getDocumentsPath();
        if (dir != null) {
          final file = File(
            '$dir/nexora-analisis-${DateTime.now().millisecondsSinceEpoch}.csv',
          );
          await file.writeAsString(csv, flush: true);
          message = 'Guardado en ${file.path}';
        }
      } on FileSystemException {
        // El CSV ya quedó en el portapapeles; se informa igual el copiado.
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on NexoraApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    appBar: AppBar(
      backgroundColor: nexoraBackground,
      title: const Text('Estadísticas'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _future = _load()),
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<NexoraStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: nexoraGold),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            );
          }
          final stats = snapshot.data ?? NexoraStats.empty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _AnimatedPercentGauge(
                percent: stats.safePercent,
                total: stats.total,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Analizados',
                      value: '${stats.total}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Alertas enviadas',
                      value: '${stats.alertsSent}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Por nivel de riesgo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              _RiskBars(low: stats.low, medium: stats.medium, high: stats.high),
              const SizedBox(height: 24),
              const Text(
                'Últimos 30 días',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              _TimelineChart(timeline: stats.timeline),
              const SizedBox(height: 24),
              if (stats.byChannel.isNotEmpty) ...[
                const Text(
                  'Por canal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in stats.byChannel.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: nexoraSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: nexoraBorder),
                        ),
                        child: Text(
                          '${_channelLabel(entry.key)}: ${entry.value}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: nexoraGoldLight,
                    side: const BorderSide(color: nexoraBorder),
                  ),
                  onPressed: _exporting ? null : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: nexoraGoldLight,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: const Text('DESCARGAR MIS DATOS (CSV)'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  String _channelLabel(String c) => switch (c) {
    'sms' => 'SMS',
    'whatsapp' => 'WhatsApp',
    'email' => 'Mail',
    _ => 'Otro',
  };
}

class _AnimatedPercentGauge extends StatelessWidget {
  const _AnimatedPercentGauge({required this.percent, required this.total});

  final int percent;
  final int total;

  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 14,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(nexoraGold),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  total == 0 ? 'sin datos aún' : 'mensajes seguros',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: nexoraSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: nexoraBorder),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: nexoraGoldLight,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _RiskBars extends StatelessWidget {
  const _RiskBars({
    required this.low,
    required this.medium,
    required this.high,
  });

  final int low;
  final int medium;
  final int high;

  @override
  Widget build(BuildContext context) {
    final total = low + medium + high;
    Widget bar(String label, int value, Color color) {
      final fraction = total == 0 ? 0.0 : value / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 14,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                '$value',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: nexoraSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nexoraBorder),
      ),
      child: Column(
        children: [
          bar('Bajo', low, severityColor(Severity.normal)),
          bar('Medio', medium, severityColor(Severity.warning)),
          bar('Alto', high, severityColor(Severity.critical)),
        ],
      ),
    );
  }
}

class _TimelineChart extends StatefulWidget {
  const _TimelineChart({required this.timeline});

  final List<(DateTime, int, int)> timeline;

  @override
  State<_TimelineChart> createState() => _TimelineChartState();
}

class _TimelineChartState extends State<_TimelineChart> {
  late int? _selected = _peakIndex;

  int? get _peakIndex {
    if (widget.timeline.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < widget.timeline.length; i++) {
      if (widget.timeline[i].$2 > widget.timeline[best].$2) best = i;
    }
    return widget.timeline[best].$2 == 0 ? null : best;
  }

  void _selectAt(Offset local, double width) {
    if (widget.timeline.isEmpty) return;
    final barWidth = width / widget.timeline.length;
    final index = (local.dx / barWidth).floor().clamp(
      0,
      widget.timeline.length - 1,
    );
    setState(() => _selected = index);
  }

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: nexoraSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: nexoraBorder),
        ),
        child: const Text(
          'Todavía no hay análisis en los últimos 30 días.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final peak = _peakIndex;
    final selected = _selected;
    final sel = selected != null && selected < widget.timeline.length
        ? widget.timeline[selected]
        : null;
    final isPeak = selected != null && selected == peak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: nexoraSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: nexoraBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _selectAt(d.localPosition, constraints.maxWidth),
              onPanUpdate: (d) =>
                  _selectAt(d.localPosition, constraints.maxWidth),
              child: CustomPaint(
                painter: _TimelinePainter(
                  timeline: widget.timeline,
                  selectedIndex: selected,
                  peakIndex: peak,
                ),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (sel != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Container(
              key: ValueKey(selected),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isPeak
                    ? nexoraWine.withValues(alpha: 0.4)
                    : nexoraSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nexoraBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isPeak ? Icons.trending_up : Icons.calendar_today,
                    size: 16,
                    color: isPeak
                        ? severityColor(Severity.critical)
                        : nexoraGoldLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPeak
                          ? 'Pico de actividad — ${_fmtDate(sel.$1)}, ${sel.$2} analizados, ${sel.$3} de riesgo alto'
                          : '${_fmtDate(sel.$1)}, ${sel.$2} analizados, ${sel.$3} de riesgo alto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'Tocá o arrastrá sobre el gráfico para ver el detalle de cada día',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.timeline,
    this.selectedIndex,
    this.peakIndex,
  });

  final List<(DateTime, int, int)> timeline;
  final int? selectedIndex;
  final int? peakIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final maxTotal = timeline.map((e) => e.$2).fold(0, (a, b) => a > b ? a : b);
    if (maxTotal == 0) return;

    final barWidth = size.width / timeline.length;
    for (var i = 0; i < timeline.length; i++) {
      final (_, total, high) = timeline[i];
      final isSelected = i == selectedIndex;
      final x = i * barWidth + barWidth * 0.2;
      final w = barWidth * 0.6;

      final totalHeight = (total / maxTotal) * size.height;
      final highHeight = (high / maxTotal) * size.height;

      final basePaint = Paint()
        ..color = nexoraBlue.withValues(alpha: isSelected ? 0.9 : 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - totalHeight, w, totalHeight),
          const Radius.circular(3),
        ),
        basePaint,
      );

      if (high > 0) {
        final highPaint = Paint()
          ..color = severityColor(
            Severity.critical,
          ).withValues(alpha: isSelected ? 1 : 0.85);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - highHeight, w, highHeight),
            const Radius.circular(3),
          ),
          highPaint,
        );
      }

      if (isSelected) {
        final outline = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = nexoraGoldLight;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - 1,
              size.height - totalHeight - 1,
              w + 2,
              totalHeight + 2,
            ),
            const Radius.circular(4),
          ),
          outline,
        );
      }

      if (i == peakIndex) {
        canvas.drawCircle(
          Offset(
            x + w / 2,
            (size.height - totalHeight - 8).clamp(4, size.height),
          ),
          3,
          Paint()..color = nexoraGoldLight,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.timeline != timeline ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.peakIndex != peakIndex;
}
