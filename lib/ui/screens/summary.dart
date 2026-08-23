/// Pestaña Resumen: el semáforo global y los hallazgos con evidencia.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.strings,
    required this.riskyApps,
    this.onOpenSystemScreen,
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final AppStrings strings;

  /// Apps de usuario con riesgo >= umbral configurado (calculado por quien
  /// posee la config); alimenta la cuarta métrica del panel rápido.
  final int riskyApps;
  final void Function(String screen)? onOpenSystemScreen;

  /// Pantalla del sistema que resuelve cada hallazgo, si existe una directa.
  (String, String)? _actionFor(Finding f) => switch (f.id) {
    'storage-low' => ('free-space', strings.actionFreeSpace),
    'battery-temp' ||
    'battery-health' => ('battery', strings.actionBatteryUsage),
    'patch-old' => ('system-update', strings.actionSystemUpdate),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final mem = snapshot.memory;
    final st = snapshot.storage;
    final bat = snapshot.battery;
    final theme = Theme.of(context);

    // Conteo por severidad para la dona interactiva.
    final donutCounts = <Severity, int>{};
    for (final f in verdict.findings) {
      donutCounts[f.severity] = (donutCounts[f.severity] ?? 0) + 1;
    }

    return ListView(
      children: [
        VerdictBanner(verdict: verdict, strings: strings),
        // Panel rápido: cuatro cifras que cuentan de 0 a su valor al entrar.
        StaggerIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                MetricTile(
                  icon: Icons.memory_rounded,
                  value: (mem.availableRatio * 100).round(),
                  label: strings.memAvailable,
                  color: nexoraBlue,
                ),
                MetricTile(
                  icon: Icons.save_rounded,
                  value: (st.freeRatio * 100).round(),
                  label: strings.storageFree,
                  color: severityGreen,
                ),
                MetricTile(
                  icon: Icons.battery_charging_full_rounded,
                  value: bat.levelPercent,
                  label: strings.batteryLevel,
                  color: nexoraGold,
                ),
                MetricTile(
                  icon: Icons.gpp_maybe_rounded,
                  value: riskyApps,
                  suffix: '',
                  label: strings.compareRisky,
                  color: nexoraRed,
                ),
              ],
            ),
          ),
        ),
        // Dona interactiva: se barre al entrar y responde al tacto.
        if (verdict.findings.isNotEmpty)
          StaggerIn(
            index: 1,
            child: SectionCard(
              title: strings.donutTitle,
              children: [
                Center(
                  child: ThreatDonut(counts: donutCounts, strings: strings),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.donutHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (verdict.findings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(strings.findingsNone),
          )
        else
          ...verdict.findings.map((f) {
            final action = _actionFor(f);
            return FindingCard(
              finding: f,
              strings: strings,
              actionLabel: action?.$2,
              onAction: action == null || onOpenSystemScreen == null
                  ? null
                  : () => onOpenSystemScreen!(action.$1),
            );
          }),
        SectionCard(
          title: strings.memTitle,
          children: [
            MeterBar(value: 1.0 - mem.availableRatio),
            const SizedBox(height: 8),
            InfoRow(label: strings.memUsed, value: formatBytes(mem.usedBytes)),
            InfoRow(
              label: strings.memAvailable,
              value: formatBytes(mem.availableBytes),
            ),
            InfoRow(
              label: strings.memTotal,
              value: formatBytes(mem.totalBytes),
            ),
          ],
        ),
        SectionCard(
          title: strings.storageTitle,
          children: [
            MeterBar(value: 1.0 - st.freeRatio),
            const SizedBox(height: 8),
            InfoRow(
              label: strings.storageFree,
              value: formatBytes(st.freeBytes),
            ),
            InfoRow(
              label: strings.storageTotal,
              value: formatBytes(st.totalBytes),
            ),
          ],
        ),
        SectionCard(
          title: strings.batteryTitle,
          children: [
            InfoRow(label: strings.batteryLevel, value: '${bat.levelPercent}%'),
            InfoRow(
              label: strings.batteryState,
              value: bat.charging
                  ? strings.batteryCharging
                  : strings.batteryDischarging,
            ),
            InfoRow(
              label: strings.batteryTemp,
              value: bat.temperatureAvailable
                  ? '${bat.temperatureCelsius.toStringAsFixed(1)} °C'
                  : strings.notAvailableOnPlatform,
            ),
            InfoRow(
              label: strings.batteryHealth,
              value: bat.temperatureAvailable
                  ? bat.healthLabel
                  : strings.notAvailableOnPlatform,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            strings.snapshotTaken(formatTimestamp(snapshot.timestampMillis)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
