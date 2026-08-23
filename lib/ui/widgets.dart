/// Piezas de UI compartidas por todas las pantallas: formateadores y los
/// widgets que componen el vocabulario visual del sensor (semáforo, tarjeta
/// de hallazgo, filas de datos).
library;

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'strings.dart';
import 'theme.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}

String formatUptime(int millis) {
  final totalMinutes = millis ~/ 60000;
  final days = totalMinutes ~/ (60 * 24);
  final hours = (totalMinutes ~/ 60) % 24;
  final minutes = totalMinutes % 60;
  return days > 0 ? '${days}d ${hours}h ${minutes}m' : '${hours}h ${minutes}m';
}

String formatTimestamp(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}

class SeverityDot extends StatelessWidget {
  const SeverityDot({super.key, required this.severity, this.size = 12});

  final Severity severity;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: severityColor(severity),
      shape: BoxShape.circle,
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class VerdictBanner extends StatelessWidget {
  const VerdictBanner({
    super.key,
    required this.verdict,
    required this.strings,
  });

  final Verdict verdict;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (verdict.severity) {
      Severity.normal => strings.verdictNormal,
      Severity.warning => strings.verdictWarning,
      Severity.critical => strings.verdictCritical,
    };
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              severityColor(verdict.severity).withValues(alpha: 0.22),
              Theme.of(context).cardColor,
            ],
            stops: const [0, 0.55],
          ),
        ),
        child: Semantics(
          label: label,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ScoreGauge(
                  score: verdict.score,
                  severity: verdict.severity,
                  size: 104,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.verdictScore(verdict.score),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (verdict.findings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final f in verdict.findings.take(4))
                                Chip(
                                  avatar: SeverityDot(
                                    severity: f.severity,
                                    size: 9,
                                  ),
                                  label: Text(f.id),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelStyle: theme.textTheme.labelSmall,
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
        ),
      ),
    );
  }
}

/// Medidor radial del puntaje global: arco de 270° que se anima de 0 al
/// puntaje actual, coloreado por severidad, con halo suave y ticks. Todo
/// dibujado a mano ([CustomPainter]) para mantener cero dependencias.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.severity,
    this.size = 96,
  });

  final int score;
  final Severity severity;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: score.clamp(0, 100).toDouble()),
    duration: const Duration(milliseconds: 950),
    curve: Curves.easeOutCubic,
    builder: (context, animated, _) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: animated / 100,
          color: severityColor(severity),
          textScale: MediaQuery.textScalerOf(context),
        ),
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.color,
    required this.textScale,
  });

  static const _startAngle = 0.75 * 3.141592653589793; // 135°
  static const _sweepAngle = 1.5 * 3.141592653589793; // 270°

  final double progress;
  final Color color;
  final TextScaler textScale;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.095;
    final inset = stroke / 2 + size.width * 0.03;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );

    // Pista completa (el arco que falta recorrer).
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // Ticks cada 25% sobre el arco.
    final tickPaint = Paint()
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.22);
    for (var t = 0; t <= 4; t++) {
      final angle = _startAngle + _sweepAngle * t / 4;
      final outer =
          rect.center + Offset.fromDirection(angle, rect.longestSide / 2 + 2);
      final inner =
          rect.center + Offset.fromDirection(angle, rect.longestSide / 2 - 4);
      canvas.drawLine(inner, outer, tickPaint);
    }

    if (progress > 0) {
      final swept = _sweepAngle * progress.clamp(0.0, 1.0);
      // Halo suave detrás del trazo activo.
      canvas.drawArc(
        rect,
        _startAngle,
        swept,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.7
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.22),
      );
      // Trazo principal.
      canvas.drawArc(
        rect,
        _startAngle,
        swept,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    // Cifra central.
    final shown = (progress.clamp(0.0, 1.0) * 100).round();
    final number = TextPainter(
      text: TextSpan(
        text: '$shown',
        style: TextStyle(
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScale,
    )..layout();
    final unit = TextPainter(
      text: TextSpan(
        text: '/100',
        style: TextStyle(
          fontSize: size.width * 0.11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScale,
    )..layout();
    number.paint(
      canvas,
      Offset(
        rect.center.dx - number.width / 2,
        rect.center.dy - number.height - 1,
      ),
    );
    unit.paint(
      canvas,
      Offset(rect.center.dx - unit.width / 2, rect.center.dy + 3),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Barra de progreso redondeada y coloreada por severidad, para reemplazar
/// los indicadores lineales pelados en las tarjetas de métricas.
class MeterBar extends StatelessWidget {
  const MeterBar({super.key, required this.value});

  /// Fracción 0..1 (cuánto se usa el recurso).
  final double value;

  Severity get severity {
    final v = value.clamp(0.0, 1.0);
    if (v < 0.60) return Severity.normal;
    if (v < 0.85) return Severity.warning;
    return Severity.critical;
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: 10,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      valueColor: AlwaysStoppedAnimation(severityColor(severity)),
    ),
  );
}

class FindingCard extends StatelessWidget {
  const FindingCard({
    super.key,
    required this.finding,
    required this.strings,
    this.actionLabel,
    this.onAction,
  });

  final Finding finding;
  final AppStrings strings;

  /// Acción de intervención: abre la pantalla del sistema donde el usuario
  /// SÍ puede actuar. Solo se muestra donde existe una pantalla directa.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final reco = strings.findingReco(finding);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SeverityDot(severity: finding.severity),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.findingTitle(finding),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(strings.findingDetail(finding)),
            if (reco.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                strings.recommendation(reco),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(actionLabel!),
                  onPressed: onAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
