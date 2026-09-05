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

  @override
  Widget build(BuildContext context) {
    final mem = snapshot.memory;
    final st = snapshot.storage;
    final bat = snapshot.battery;
    final net = snapshot.network;
    final theme = Theme.of(context);
    final (percent, shieldLevel) = protectionGauge(verdict.severity);
    final shieldColor = riskLevelColor(shieldLevel);

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
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.battery_charging_full_rounded,
                  label: strings.batteryLevel,
                  value: '${bat.levelPercent}%',
                  barValue: bat.levelPercent / 100,
                  color: nexoraGold,
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
                ),
                const SizedBox(height: ntGapSmall),
                ValueRow(
                  icon: Icons.save_outlined,
                  label: strings.storageFree,
                  value: '${formatBytes(st.freeBytes)} / ${formatBytes(st.totalBytes)}',
                  barValue: st.freeRatio,
                  color: severityGreen,
                ),
                const Divider(height: ntGap + 8, color: nexoraBorder),
                // CPU: la plataforma no expone la carga — se muestra la
                // verdad en vez de un porcentaje inventado.
                ValueRow(
                  icon: Icons.settings_input_component,
                  label: strings.dashCpuCores,
                  value: '${snapshot.device.cpuCores}',
                  color: nexoraBlue,
                ),
                const SizedBox(height: ntGapSmall),
                if (net.connected)
                  ValueRow(
                    icon: Icons.arrow_downward_rounded,
                    label: strings.dashNetworkDown,
                    value: '${net.downstreamKbps} kbps',
                    barValue: netDown,
                    color: nexoraBlue,
                  )
                else
                  ValueRow(
                    icon: Icons.arrow_downward_rounded,
                    label: strings.dashNetworkDown,
                    value: strings.dashNetworkOff,
                    barValue: 0,
                    color: nexoraBlue,
                  ),
                const SizedBox(height: ntGapSmall),
                if (net.connected)
                  ValueRow(
                    icon: Icons.arrow_upward_rounded,
                    label: strings.dashNetworkUp,
                    value: '${net.upstreamKbps} kbps',
                    barValue: netUp,
                    color: nexoraBlue,
                  )
                else
                  ValueRow(
                    icon: Icons.arrow_upward_rounded,
                    label: strings.dashNetworkUp,
                    value: strings.dashNetworkOff,
                    barValue: 0,
                    color: nexoraBlue,
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