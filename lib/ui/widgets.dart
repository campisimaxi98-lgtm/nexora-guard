/// Piezas de UI compartidas por todas las pantallas: formateadores y los
/// widgets que componen el vocabulario visual del sensor (semáforo, tarjeta
/// de hallazgo, filas de datos).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'nexora_logo.dart';
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

// ---------------------------------------------------------------------------
// Panel interactivo y efectos de movimiento (v1.0.0). Todo dibujado a mano
// con CustomPainter: cero dependencias, como el resto del proyecto.
// ---------------------------------------------------------------------------

/// Número que cuenta de 0 a su valor final con curva easeOutCubic. Da vida
/// a las métricas sin costo: un solo TweenAnimationBuilder por cifra.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber(this.value, {super.key, this.suffix = '', this.style});

  final int value;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeOutCubic,
    builder: (context, animated, _) =>
        Text('${animated.round()}$suffix', style: style),
  );
}

/// Tile compacto del panel rápido: icono tintado + cifra animada + rótulo.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.suffix = '%',
    this.color = nexoraGold,
  });

  final IconData icon;
  final int value;
  final String label;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          AnimatedNumber(
            value,
            suffix: suffix,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada escalonada: desvanece y desliza su hijo con una demora proporcional
/// al índice. Para que las tarjetas "lleguen" en cascada al abrir Resumen.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Posición en la cascada; cada paso suma ~70 ms (tope 350 ms).
  final int index;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 70).clamp(0, 350));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Dona interactiva de hallazgos por severidad: entra barriendo sus arcos,
/// responde al tacto (arco o leyenda), resalta el tramo elegido y muestra el
/// porcentaje en el centro.
class ThreatDonut extends StatefulWidget {
  const ThreatDonut({
    super.key,
    required this.counts,
    required this.strings,
    this.size = 190,
  });

  /// Hallazgos por severidad; los tramos con conteo 0 no se dibujan.
  final Map<Severity, int> counts;
  final AppStrings strings;
  final double size;

  @override
  State<ThreatDonut> createState() => _ThreatDonutState();
}

class _ThreatDonutState extends State<ThreatDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  Severity? _selected;

  @override
  void initState() {
    super.initState();
    // La captura puede llegar después del primer frame: re-animar cuando
    // cambien los conteos mantiene la dona viva en cada actualización.
  }

  @override
  void didUpdateWidget(covariant ThreatDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.counts.toString() != widget.counts.toString()) {
      _entrance.forward(from: 0);
      _selected = null;
    }
  }

  List<Severity> get _segments => [
    for (final s in Severity.values)
      if ((widget.counts[s] ?? 0) > 0) s,
  ];

  int get _total => [
    for (final s in _segments) widget.counts[s] ?? 0,
  ].fold(0, (a, b) => a + b);

  void _handleTap(Offset local) {
    final segments = _segments;
    if (segments.isEmpty) return;
    final size = widget.size;
    final center = Offset(size / 2, size / 2);
    final delta = local - center;
    final radius = delta.distance;
    final stroke = size * 0.13;
    // Fuera del anillo (con margen de dedo): deselecciona.
    if (radius < size / 2 - stroke - 8 || radius > size / 2 + stroke / 2 + 10) {
      setState(() => _selected = null);
      return;
    }
    // Ángulo horario medido desde arriba (-90°).
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2 + 2 * math.pi;
    angle %= 2 * math.pi;
    final total = _total;
    var acc = 0.0;
    for (final s in segments) {
      acc += (widget.counts[s] ?? 0) / total * 2 * math.pi;
      if (angle <= acc) {
        setState(() => _selected = (_selected == s ? null : s));
        return;
      }
    }
    setState(() => _selected = null);
  }

  String _labelFor(Severity s) => switch (s) {
    Severity.normal => widget.strings.severityNormal,
    Severity.warning => widget.strings.severityWarning,
    Severity.critical => widget.strings.severityCritical,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = _segments;
    if (segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(widget.strings.donutEmpty),
      );
    }
    final total = _total;
    return Column(
      children: [
        SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, _) => GestureDetector(
                  onTapUp: (details) => _handleTap(details.localPosition),
                  child: CustomPaint(
                    size: Size.square(widget.size),
                    painter: _DonutPainter(
                      severities: segments,
                      counts: [for (final s in segments) widget.counts[s] ?? 0],
                      progress: Curves.easeOutCubic.transform(_entrance.value),
                      selected: _selected,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(_selected),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selected == null
                            ? '$total'
                            : '${((widget.counts[_selected] ?? 0) / total * 100).round()} %',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selected == null
                            ? widget.strings.metricSignals
                            : _labelFor(_selected!),
                        style: TextStyle(
                          fontSize: 11,
                          color: _selected == null
                              ? theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.65,
                                )
                              : severityColor(_selected!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in segments)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _selected = (_selected == s ? null : s)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selected == s
                          ? nexoraGold.withValues(alpha: 0.7)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SeverityDot(severity: s, size: 9),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelFor(s),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.counts[s]} · '
                            '${((widget.counts[s] ?? 0) / total * 100).round()} %',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pintor de la dona: pista tenue + arcos que entran en barrido continuo
/// según [progress]; el tramo seleccionado engrosa y los demás se atenúan.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.severities,
    required this.counts,
    required this.progress,
    required this.selected,
  });

  final List<Severity> severities;
  final List<int> counts;
  final double progress;
  final Severity? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final stroke = size.width * 0.13;
    final inset = stroke / 2 + size.width * 0.02;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );

    // Pista completa.
    canvas.drawCircle(
      rect.center,
      rect.longestSide / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.07),
    );

    const startAngle = -math.pi / 2;
    var sweepLeft = progress.clamp(0.0, 1.0) * 2 * math.pi;
    var angle = startAngle;
    for (var i = 0; i < severities.length; i++) {
      final frac = counts[i] / total;
      final fullSweep = frac * 2 * math.pi;
      final visible = sweepLeft.clamp(0.0, fullSweep);
      if (visible > 0) {
        final isSelected = selected == severities[i];
        canvas.drawArc(
          rect,
          angle,
          visible,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? stroke + 6 : stroke
            ..color = severityColor(
              severities[i],
            ).withValues(alpha: selected == null || isSelected ? 1 : 0.38),
        );
      }
      sweepLeft -= fullSweep;
      angle += fullSweep;
      if (sweepLeft <= 0) break;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.selected != selected ||
      oldDelegate.counts != counts;
}

/// Serie para [InteractiveLineChart].
class LineSeries {
  const LineSeries({
    required this.label,
    required this.points,
    required this.color,
    this.formatValue,
  });

  final String label;
  final List<int> points;
  final Color color;

  /// Formato amigable del valor crudo para la burbuja (ej. °C).
  final String Function(int value)? formatValue;
}

/// Gráfico de líneas interactivo: dibuja su trazado al entrar, y responde al
/// toque/arrastre mostrando un indicador vertical con burbuja de valores por
/// punto. Sin dependencias: pintura y gestos puros de Flutter.
class InteractiveLineChart extends StatefulWidget {
  const InteractiveLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    this.height = 150,
    this.gridColor,
  });

  final List<LineSeries> series;
  final List<String> xLabels;
  final double height;
  final Color? gridColor;

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  int? _scrub;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _scrubTo(double dx, double width) {
    final n = widget.xLabels.length;
    if (n < 2) return;
    setState(() {
      _scrub = (dx / width * (n - 1)).round().clamp(0, n - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grid = widget.gridColor ?? Colors.white.withValues(alpha: 0.12);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _scrubTo(d.localPosition.dx, constraints.maxWidth),
            onHorizontalDragStart: (d) =>
                _scrubTo(d.localPosition.dx, constraints.maxWidth),
            onHorizontalDragUpdate: (d) =>
                _scrubTo(d.localPosition.dx, constraints.maxWidth),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _TrendScrubPainter(
                series: widget.series,
                xLabels: widget.xLabels,
                gridColor: grid,
                reveal: Curves.easeOutCubic.transform(_reveal.value),
                scrub: _scrub,
                bubbleBase: Theme.of(context).cardColor,
                textScale: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendScrubPainter extends CustomPainter {
  _TrendScrubPainter({
    required this.series,
    required this.xLabels,
    required this.gridColor,
    required this.reveal,
    required this.scrub,
    required this.bubbleBase,
    required this.textScale,
  });

  final List<LineSeries> series;
  final List<String> xLabels;
  final Color gridColor;
  final double reveal;
  final int? scrub;
  final Color bubbleBase;
  final TextScaler textScale;

  TextPainter _text(
    String text, {
    double fontSize = 11,
    Color color = Colors.white,
    bool bold = false,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScale,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = xLabels.length;
    if (n < 2) return;

    // Rejilla horizontal.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final pct in const [0, 50, 100]) {
      final y = size.height * (1 - pct / 100);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));

    final step = size.width / (n - 1);
    Offset pointAt(int i, int v) =>
        Offset(step * i, size.height * (1 - v.clamp(0, 100) / 100));

    for (final s in series) {
      if (s.points.length < 2) continue;
      // Relleno bajo la primera serie para dar profundidad.
      if (s == series.first) {
        final fill = Path()..moveTo(0, size.height);
        for (var i = 0; i < s.points.length; i++) {
          fill.lineTo(pointAt(i, s.points[i]).dx, pointAt(i, s.points[i]).dy);
        }
        fill.lineTo(step * (s.points.length - 1), size.height);
        fill.close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.20),
                s.color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        );
      }
      final line = Path();
      for (var i = 0; i < s.points.length; i++) {
        final p = pointAt(i, s.points[i]);
        i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      final dot = Paint()..color = s.color;
      for (var i = 0; i < s.points.length; i++) {
        canvas.drawCircle(pointAt(i, s.points[i]), 2.4, dot);
      }
    }
    canvas.restore();

    // Indicador de arrastre + burbuja de valores.
    final idx = scrub;
    if (idx == null || idx >= n) return;
    final x = step * idx;
    final guide = Paint()
      ..color = nexoraGoldLight.withValues(alpha: 0.75)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);

    for (final s in series) {
      if (idx < s.points.length) {
        final p = pointAt(idx, s.points[idx]);
        canvas.drawCircle(
          p,
          6,
          Paint()..color = s.color.withValues(alpha: 0.28),
        );
        canvas.drawCircle(p, 3.4, Paint()..color = s.color);
      }
    }

    final title = _text(xLabels[idx], bold: true);
    final rows = <TextPainter>[
      for (final s in series)
        if (idx < s.points.length)
          _text(
            '${s.label} ${s.formatValue?.call(s.points[idx]) ?? '${s.points[idx]}'}',
            color: s.color,
          ),
    ];
    final w = [title.width, for (final r in rows) r.width].reduce(math.max);
    final bubbleW = w + 18;
    final bubbleH =
        title.height + rows.fold(0.0, (a, r) => a + r.height + 3) + 12;
    var left = x - bubbleW / 2;
    left = left.clamp(4.0, size.width - bubbleW - 4);
    final top = 4.0;
    final rect = Rect.fromLTWH(left, top, bubbleW, bubbleH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(
      rrect,
      Paint()..color = bubbleBase.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = nexoraGold.withValues(alpha: 0.45),
    );
    var ty = top + 6;
    title.paint(canvas, Offset(left + 9, ty));
    ty += title.height + 4;
    for (final r in rows) {
      r.paint(canvas, Offset(left + 9, ty));
      ty += r.height + 3;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendScrubPainter oldDelegate) =>
      oldDelegate.scrub != scrub ||
      oldDelegate.reveal != reveal ||
      oldDelegate.series != series;
}

/// Pantalla de escaneo: radar giratorio con ecos que destellan cuando el haz
/// pasa sobre ellos y el escudo NEXORA en el centro. Reemplaza al spinner
/// genérico mientras se captura el estado del dispositivo.
class RadarScan extends StatefulWidget {
  const RadarScan({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<RadarScan> createState() => _RadarScanState();
}

class _RadarScanState extends State<RadarScan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 250,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(250),
                    painter: _RadarPainter(t: _spin.value),
                  ),
                  const NexoraLogo(size: 84, showRing: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          // Respiración del texto sincronizada con el giro del radar.
          FadeTransition(
            opacity: Tween<double>(begin: 0.55, end: 1).animate(
              CurvedAnimation(
                parent: _spin,
                curve: const Interval(0, 0.5, curve: Curves.easeInOut),
              ),
            ),
            child: Text(
              widget.strings.loading,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Anillos concéntricos, sector de barrido dorado con estela y ecos fijos
/// que brillan justo cuando el haz los cruza. Determinístico entre frames.
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t});

  /// Fase del giro, 0..1 (una vuelta completa).
  final double t;

  static const _echoes = [
    (0.4, 0.52),
    (1.5, 0.78),
    (2.4, 0.36),
    (3.3, 0.66),
    (4.2, 0.85),
    (5.1, 0.48),
    (5.9, 0.72),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2 - 6;

    // Anillos guía.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = nexoraBlue.withValues(alpha: 0.35);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxR * i / 4, ring);
    }
    // Cruces finas.
    canvas.drawLine(
      center - Offset(maxR, 0),
      center + Offset(maxR, 0),
      ring..color = nexoraBlue.withValues(alpha: 0.18),
    );
    canvas.drawLine(center - Offset(0, maxR), center + Offset(0, maxR), ring);

    // Sector de barrido: estela en escalera de arcos que se apagan + haz
    // frontal. Determinístico y sin matemática de gradientes cónicos.
    const twoPi = 2 * math.pi;
    final sweepAngle = t * twoPi;
    final step = 0.07;
    for (var k = 16; k >= 1; k--) {
      final alpha = 0.30 * math.exp(-k * 0.22);
      if (alpha < 0.01) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxR),
        sweepAngle - k * step,
        step,
        true,
        Paint()..color = nexoraGold.withValues(alpha: alpha),
      );
    }
    // Borde frontal del haz.
    canvas.drawLine(
      center,
      center + Offset.fromDirection(sweepAngle, maxR),
      Paint()
        ..color = nexoraGoldLight.withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Ecos que destellan al ser barridos por el haz.
    for (final (baseAngle, radiusFrac) in _echoes) {
      final angle = baseAngle % twoPi;
      var d = (sweepAngle - angle) % twoPi;
      if (d < 0) d += twoPi;
      final glow = math.exp(-d * 2.4); // estela que se apaga tras el paso
      final alpha = 0.16 + 0.74 * glow;
      final pos = center + Offset.fromDirection(angle, maxR * radiusFrac);
      canvas.drawCircle(
        pos,
        3.2 + 2.4 * glow,
        Paint()..color = severityGreen.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.t != t;
}
