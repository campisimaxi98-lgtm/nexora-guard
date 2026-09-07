/// Dashboard ("Inicio", FASE 4) — resumen visual del estado real del equipo.
///
/// El "Nivel de protección" y su % son una traducción amigable del
/// [Verdict.severity] que calcula `rule_engine.dart` (no un dato inventado):
/// severidad normal/precaución/crítica se expresa como un semáforo con
/// número al lado. Las barras de "recursos en vivo" usan solo datos reales
/// del snapshot (RAM, batería, temperatura, almacenamiento, red); la carga
/// de CPU no la expone la plataforma y la UI lo dice, nunca lo simula.
library;

import 'package:flutter/material.dart';

import '../../core/app_risk_level.dart';
import '../../core/history_store.dart';
import '../../core/models.dart';
import '../components.dart';
import '../nexora_logo.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

/// Índice de protección 0..100 + nivel de la escala de 4.
(int, AppRiskLevel) protectionGauge(Severity s) => switch (s) {
  Severity.normal => (96, AppRiskLevel.safe),
  Severity.warning => (58, AppRiskLevel.attention),
  Severity.critical => (26, AppRiskLevel.critical),
};

/// Salud compuesta REAL (0..100) del equipo y cuántos de los 5 sensores
/// reportaron un dato real en esta captura. Cada componente usa solo los
/// valores que la plataforma entregó de verdad; los no disponibles no
/// penalizan ni se inventan.
///
/// Peso: memoria 25 %, almacenamiento 25 %, batería 20 %, CPU 15 %,
/// seguridad (red) 15 %.
(int, int) deviceHealth(Snapshot s, Verdict verdict) {
  var numerator = 0.0;
  var weight = 0.0;
  var active = 0;

  // Memoria: mis libres como salud (1 - uso).
  if (s.memory.totalBytes > 0) {
    weight += 0.25;
    numerator += 0.25 * s.memory.availableRatio;
    active++;
  }

  // Almacenamiento: % libre.
  if (s.storage.totalBytes > 0) {
    weight += 0.25;
    numerator += 0.25 * s.storage.freeRatio.clamp(0.0, 1.0);
    active++;
  }

  // Batería: nivel real + penalización honesta por calor excesivo.
  if (s.battery.levelPercent >= 0) {
    weight += 0.20;
    var b = s.battery.levelPercent / 100.0;
    if (s.battery.temperatureAvailable && s.battery.temperatureCelsius >= 45) {
      b = (b * 0.6).clamp(0.0, 1.0);
    }
    numerator += 0.20 * b;
    active++;
  }

  // CPU: solo si la plataforma la entrega (si no, no suma sentido de peso).
  if (s.device.cpuLoadAvailable) {
    weight += 0.15;
    numerator += 0.15 * (1.0 - (s.device.cpuLoadPercent / 100.0).clamp(0.0, 1.0));
    active++;
  }

  // Reporte de seguridad de la red (veredicto del motor de reglas).
  weight += 0.15;
  numerator += switch (verdict.severity) {
    Severity.normal => 0.15,
    Severity.warning => 0.09,
    Severity.critical => 0.04,
  };
  active++;

  if (weight <= 0) return (0, active);
  var pct = ((numerator / weight) * 100).round();
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return (pct, active);
}

class NexoraDashboardScreen extends StatelessWidget {
  const NexoraDashboardScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.history,
    required this.strings,
    this.onRefresh,
    this.onOpenTab,
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final List<HistoryRow> history;
  final AppStrings strings;
  final Future<void> Function()? onRefresh;
  final void Function(String tabId)? onOpenTab;

  String _severityChip(Severity s) => switch (s) {
    Severity.normal => strings.dashStatusNormal,
    Severity.warning => strings.dashStatusWarning,
    Severity.critical => strings.dashStatusCritical,
  };

  String _riskLabel(AppRiskLevel level) => switch (level) {
    AppRiskLevel.safe => strings.riskSafe,
    AppRiskLevel.attention => strings.riskAttention,
    AppRiskLevel.suspicious => strings.riskSuspicious,
    AppRiskLevel.critical => strings.riskCritical,
  };

  Color _tempColor(double c) {
    if (c >= 45) return nexoraRed;
    if (c >= 40) return nexoraOrange;
    return nexoraGold;
  }

  void _open(String tabId) {
    final onOpenTab = this.onOpenTab;
    if (onOpenTab != null) onOpenTab(tabId);
  }

  /// Color del porcentaje central por nivel de salud (FASE 8): verde
  /// óptimo, ámbar atención, naranja sospechoso, rojo crítico.
  Color _healthColor(int health) {
    if (health >= 80) return severityGreen;
    if (health >= 60) return severityYellow;
    if (health >= 40) return nexoraOrange;
    return nexoraRed;
  }

  /// Explica la escala de colores de la esfera al tocarla (FASE 8).
  void _showHealthScale(
    BuildContext context,
    int health,
    int activeSensors,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: nexoraSurfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ntPad + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderRow(
                icon: Icons.donut_large,
                title: strings.donutScaleTitle,
              ),
              const SizedBox(height: ntGapSmall),
              Text(
                '${strings.donutScaleIntro} ${strings.donutScaleSensors(activeSensors)}',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: ntGap),
              _ScaleRow(color: severityGreen, text: strings.donutScaleGood),
              _ScaleRow(color: severityYellow, text: strings.donutScaleFair),
              _ScaleRow(color: nexoraOrange, text: strings.donutScaleWarn),
              _ScaleRow(color: nexoraRed, text: strings.donutScaleBad),
              const SizedBox(height: ntGapSmall),
              Text(
                '${strings.donutCenterHint} Estado actual: $health%.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mem = snapshot.memory;
    final st = snapshot.storage;
    final bat = snapshot.battery;
    final net = snapshot.network;
    final theme = Theme.of(context);
    final (percent, shieldLevel) = protectionGauge(verdict.severity);
    final shieldColor = riskLevelColor(shieldLevel);
    final (healthPercent, activeSensors) = deviceHealth(snapshot, verdict);

    // Apps con mayor señales de riesgo, para el resumen del Inicio.
    final risky = snapshot.apps
        .where((a) => classifyAppRisk(a) != AppRiskLevel.safe)
        .toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    final topApps = risky.take(3).toList();

    // Velocidad de red para las barras (cap visual honesto informado aparte).
    const downCap = 10000.0; // ≈ 10 Mbps
    const upCap = 2000.0; // ≈ 2 Mbps
    final netDown = net.downstreamKbps / downCap;
    final netUp = net.upstreamKbps / upCap;

    // Dona interactiva: segmentos con datos reales que abren pantallas reales.
    final totalApps = snapshot.apps.length;
    final appsAtRisk = snapshot.apps
        .where((a) => classifyAppRisk(a) != AppRiskLevel.safe)
        .length;
    final donutSegments = <NxDonutSegment>[
      NxDonutSegment(
        id: 'apps',
        label: strings.donutLegendApps,
        color: nexoraOrange,
        ratio: totalApps > 0 ? appsAtRisk / totalApps : 0,
        subtitle: '$appsAtRisk/$totalApps',
        onTap: () => _open('apps'),
      ),
      NxDonutSegment(
        id: 'network',
        label: strings.donutLegendNetwork,
        color: nexoraBlue,
        ratio: net.connected ? 1 : 0.08,
        subtitle: net.connected ? strings.dashNetworkOn : strings.donutNetworkOff,
        onTap: () => _open('network'),
      ),
      NxDonutSegment(
        id: 'battery',
        label: strings.donutLegendBattery,
        color: nexoraGold,
        ratio: bat.levelPercent / 100,
        subtitle: '${bat.levelPercent}%',
        onTap: () => _open('device'),
      ),
      NxDonutSegment(
        id: 'storage',
        label: strings.donutLegendStorage,
        color: severityGreen,
        ratio: st.freeRatio.clamp(0.0, 1.0),
        subtitle: '${(st.freeRatio * 100).round()}%',
        onTap: () => _open('device'),
      ),
    ];

    final content = NexoraMaxWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(ntPad, 10, ntPad, 28),
        children: [
          // Encabezado de bienvenida + estado al capturar el snapshot.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXORA GUARD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: nexoraGoldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.dashHello,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      strings.dashAllGood,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const NexoraLogo(size: 44, showRing: false),
            ],
          ),
          const SizedBox(height: ntGap),

          // ── Tarjeta escudo: nivel de protección ──
          NexoraCard(
            glow: shieldLevel != AppRiskLevel.safe,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderRow(
                  icon: Icons.shield_outlined,
                  title: strings.dashProtectionTitle,
                  iconColor: shieldColor,
                ),
                const SizedBox(height: ntPadSmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: shieldColor,
                      ),
                    ),
                    const SizedBox(width: ntGap),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: LevelBadge(
                          level: shieldLevel,
                          label: _severityChip(verdict.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ntGapSmall),
                ClipRRect(
                  borderRadius: BorderRadius.circular(ntRadiusPill),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    backgroundColor: nexoraBorder.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(shieldColor),
                  ),
                ),
                const SizedBox(height: ntGapSmall),
                Text(
                  verdict.findings.isEmpty
                      ? strings.aiAlertNone
                      : strings.dashFindings(verdict.findings.length),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: ntGap),

          // ── Gráfica interactiva de tendencia (FASE 4) ──
          NexoraCard(
            child: Padding(
              padding: const EdgeInsets.all(ntPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderRow(
                    icon: Icons.show_chart,
                    title: strings.chartTrendTitle,
                  ),
                  const SizedBox(height: ntGapSmall),
                  NexoraInteractiveChart(rows: history, strings: strings),
                ],
              ),
            ),
          ),
          const SizedBox(height: ntGap),

          // ── Dona interactiva: estado por área, segmentos que navegan ──
          NexoraDonut(
            segments: donutSegments,
            strings: strings,
            centerPercent: healthPercent.toDouble(),
            centerColor: _healthColor(healthPercent),
            onCenterTap: () =>
                _showHealthScale(context, healthPercent, activeSensors),
          ),
          const SizedBox(height: ntGap),

          // ── Accesos rápidos a pantallas reales ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ntGap,
            crossAxisSpacing: ntGap,
            childAspectRatio: 2.1,
            children: [
              _QuickAction(
                icon: Icons.apps,
                label: strings.dashAppsTitle,
                sublabel: strings.dashAppsSub,
                onTap: () => _open('apps'),
              ),
              _QuickAction(
                icon: Icons.flag_outlined,
                label: strings.dashSignalsTitle,
                sublabel: strings.dashSignalsSub,
                onTap: () => _open('flagged'),
              ),
              _QuickAction(
                icon: Icons.wifi,
                label: strings.dashNetworkKebab,
                sublabel: strings.dashNetworkNote,
                onTap: () => _open('network'),
              ),
              _QuickAction(
                icon: Icons.phone_android,
                label: strings.tabDevice,
                sublabel: snapshot.device.model,
                onTap: () => _open('device'),
              ),
            ],
          ),
          const SizedBox(height: ntGap),

          // ── Recursos en vivo (datos reales, nunca simulados) ──
          NexoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderRow(
                  icon: Icons.monitor_heart_outlined,
                  title: strings.dashResourceTitle,
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.memory_rounded,
                  label: strings.memUsed,
                  value: '${formatBytes(mem.usedBytes)} / ${formatBytes(mem.totalBytes)}',
                  barValue: 1.0 - mem.availableRatio,
                  color: nexoraBlue,
                  onTap: () => _open('device'),
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.battery_charging_full_rounded,
                  label: strings.batteryLevel,
                  value: '${bat.levelPercent}%',
                  barValue: bat.levelPercent / 100,
                  color: nexoraGold,
                  onTap: () => _open('device'),
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.thermostat_rounded,
                  label: strings.batteryTemp,
                  value: bat.temperatureAvailable
                      ? '${bat.temperatureCelsius.toStringAsFixed(1)} °C'
                      : strings.notAvailableOnPlatform,
                  barValue: bat.temperatureAvailable
                      ? (bat.temperatureCelsius / 45).clamp(0.0, 1.0)
                      : 0,
                  color: bat.temperatureAvailable
                      ? _tempColor(bat.temperatureCelsius)
                      : nexoraBlue,
                  onTap: () => _open('device'),
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.save_outlined,
                  label: strings.storageFree,
                  value: '${formatBytes(st.freeBytes)} / ${formatBytes(st.totalBytes)}',
                  barValue: st.freeRatio,
                  color: severityGreen,
                  onTap: () => _open('storage'),
                ),
                const Divider(height: ntGap + 8, color: nexoraBorder),
                // CPU: la carga es REAL (muestreo delta del nativo) cuando la
                // plataforma la entrega; si no, se muestra la verdad.
                ValueRow(
                  icon: Icons.settings_input_component,
                  label: strings.dashCpuCores,
                  value: '${snapshot.device.cpuCores}',
                  color: nexoraBlue,
                  onTap: () => _open('device'),
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.speed,
                  label: strings.dashCpuLoad,
                  value: snapshot.device.cpuLoadAvailable
                      ? '${snapshot.device.cpuLoadPercent}%'
                      : strings.notAvailableOnPlatform,
                  barValue: snapshot.device.cpuLoadAvailable
                      ? (snapshot.device.cpuLoadPercent / 100).clamp(0.0, 1.0)
                      : 0,
                  color: snapshot.device.cpuLoadAvailable
                      ? (snapshot.device.cpuLoadPercent >= 80
                            ? nexoraRed
                            : nexoraBlue)
                      : nexoraBlue,
                  onTap: () => _open('device'),
                ),
                const SizedBox(height: ntGapSmall),
                if (net.connected)
                  ValueRow(
                    icon: Icons.arrow_downward_rounded,
                    label: strings.dashNetworkDown,
                    value: '${net.downstreamKbps} kbps',
                    barValue: netDown,
                    color: nexoraBlue,
                    onTap: () => _open('network'),
                  )
                else
                  ValueRow(
                    icon: Icons.arrow_downward_rounded,
                    label: strings.dashNetworkDown,
                    value: strings.dashNetworkOff,
                    barValue: 0,
                    color: nexoraBlue,
                    onTap: () => _open('network'),
                  ),
                const SizedBox(height: ntGapSmall),
                if (net.connected)
                  ValueRow(
                    icon: Icons.arrow_upward_rounded,
                    label: strings.dashNetworkUp,
                    value: '${net.upstreamKbps} kbps',
                    barValue: netUp,
                    color: nexoraBlue,
                    onTap: () => _open('network'),
                  )
                else
                  ValueRow(
                    icon: Icons.arrow_upward_rounded,
                    label: strings.dashNetworkUp,
                    value: strings.dashNetworkOff,
                    barValue: 0,
                    color: nexoraBlue,
                    onTap: () => _open('network'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ntGap),

          // ── Resumen de apps con señales + VER ANÁLISIS ──
          NexoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderRow(
                  icon: Icons.verified_user_outlined,
                  title: strings.dashAppsTitle,
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: nexoraGoldLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _open('flagged'),
                    child: Text(
                      strings.dashViewAnalysis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ntGapSmall),
                if (topApps.isEmpty)
                  Text(strings.dashNoRiskyApps, style: theme.textTheme.bodySmall)
                else
                  for (final app in topApps) ...[
                    _AppSummaryRow(
                      app: app,
                      levelLabel: _riskLabel(classifyAppRisk(app)),
                      onTap: () => _open('flagged'),
                    ),
                    if (app != topApps.last)
                      const Divider(height: 1, color: nexoraBorder),
                  ],
              ],
            ),
          ),
          const SizedBox(height: ntGap),

          // ── Actividad reciente (historial real por captura) ──
          NexoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderRow(
                  icon: Icons.history,
                  title: strings.dashRecentTitle,
                ),
                const SizedBox(height: ntGapSmall),
                if (history.isEmpty)
                  Text(strings.dashHistEmpty, style: theme.textTheme.bodySmall)
                else
                  for (final row in _recentRows()) _ActivityRow(row: row, strings: strings),
              ],
            ),
          ),
          const SizedBox(height: ntGap),
          Text(
            strings.snapshotTaken(formatTimestamp(snapshot.timestampMillis)),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    final refresh = onRefresh;
    if (refresh == null) return content;
    return RefreshIndicator(
      onRefresh: refresh,
      color: nexoraGold,
      backgroundColor: nexoraSurfaceRaised,
      child: content,
    );
  }

  /// Últimas 4 capturas, de la más reciente hacia atrás.
  List<HistoryRow> _recentRows() {
    final rows = history.length > 4 ? history.sublist(history.length - 4) : history;
    return rows.reversed.toList();
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NexoraCard(
    padding: const EdgeInsets.symmetric(horizontal: ntPadSmall, vertical: 10),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: nexoraGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(ntRadiusSmall),
          ),
          child: Icon(icon, color: nexoraGoldLight, size: 20),
        ),
        const SizedBox(width: ntGapSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              Text(
                sublabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AppSummaryRow extends StatelessWidget {
  const _AppSummaryRow({
    required this.app,
    required this.levelLabel,
    required this.onTap,
  });

  final AppRisk app;
  final String levelLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(ntRadiusSmall),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: nexoraSurfaceRaised,
            child: Text(
              app.label.isEmpty ? '?' : app.label.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: ntGapSmall),
          Expanded(
            child: Text(
              app.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          LevelBadge(
            level: classifyAppRisk(app),
            label: levelLabel,
            compact: true,
          ),
        ],
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.row, required this.strings});

  final HistoryRow row;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(row.timestampMillis);
    String two(int v) => v.toString().padLeft(2, '0');
    final label = switch (row.severity) {
      Severity.normal => strings.dashHistNormal,
      Severity.warning => strings.dashHistWarning,
      Severity.critical => strings.dashHistCritical,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        switch (row.severity) {
          Severity.normal => Icons.check_circle,
          Severity.warning => Icons.warning_amber_rounded,
          Severity.critical => Icons.error,
        },
        color: severityColor(row.severity),
      ),
      title: Text(label, style: const TextStyle(fontSize: 13.5)),
      subtitle: Text(
        '${two(dt.hour)}:${two(dt.minute)} · ${strings.dashRiskScore(row.score)}',
        style: const TextStyle(fontSize: 11.5),
      ),
    );
  }
}

/// Fila de la escala de colores: círculo + explicación (nunca color solo).
class _ScaleRow extends StatelessWidget {
  const _ScaleRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    ),
  );
}