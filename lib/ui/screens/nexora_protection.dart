/// "Protección Web" — estado real de la conexión (transporte, VPN
/// detectada, medida/no medida) más los hallazgos de red que ya calcula
/// `rule_engine.dart`. NEXORA GUARD no implementa un túnel VPN propio: si
/// no hay ninguna VPN activa en el sistema, se lo decimos así en vez de
/// simular una conexión protegida que no existe.
library;

import 'package:flutter/material.dart';

import '../../core/app_risk_level.dart';
import '../../core/models.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'nexora_apps.dart';

class NexoraProtectionScreen extends StatelessWidget {
  const NexoraProtectionScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.strings,
    required this.apps,
    required this.onOpenApp,
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final AppStrings strings;
  final List<AppRisk> apps;

  /// Abre la ficha REAL de una app en los Ajustes del sistema.
  final void Function(String packageName) onOpenApp;

  @override
  Widget build(BuildContext context) {
    final network = snapshot?.network;
    final networkFindings = verdict == null
        ? const <Finding>[]
        : verdict!.findings
              .where((f) => f.id.startsWith('network') || f.id.contains('vpn'))
              .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: nexoraGoldLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  strings.protectionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [nexoraSurfaceRaised, nexoraSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: nexoraBorder),
            ),
            child: Column(
              children: [
                Icon(
                  network?.connected == true ? Icons.public : Icons.public_off,
                  size: 46,
                  color: network?.connected == true
                      ? nexoraBlue
                      : Colors.white38,
                ),
                const SizedBox(height: 10),
                Text(
                  network == null
                      ? strings.protectionNoData
                      : network.connected
                      ? strings.protectionConnected(network.transport)
                      : strings.protectionDisconnected,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  network?.vpnActive == true
                      ? strings.protectionVpnActive
                      : strings.protectionVpnNone,
                  style: TextStyle(
                    color: network?.vpnActive == true
                        ? severityColor(Severity.normal)
                        : Colors.white54,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NetStat(
                  label: strings.protectionDown,
                  value: network == null
                      ? '—'
                      : '${network.downstreamKbps} kbps',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NetStat(
                  label: strings.protectionUp,
                  value: network == null ? '—' : '${network.upstreamKbps} kbps',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NetStat(
                  label: strings.protectionMetered,
                  value: network == null
                      ? '—'
                      : (network.metered ? strings.yes : strings.no),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            strings.protectionFindingsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          if (networkFindings.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nexoraSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nexoraBorder),
              ),
              child: Text(
                strings.protectionFindingsNone,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            for (final f in networkFindings)
              FindingCard(
                finding: f,
                strings: strings,
                onTap: () => showFindingDetail(context, strings, f),
              ),
          const SizedBox(height: 24),

          // ── Aplicaciones: permisos y riesgo reales de cada app (FASE 8) ──
          SectionHeaderRow(
            icon: Icons.apps,
            title: strings.protectionAppsTitle,
          ),
          const SizedBox(height: 4),
          Text(
            strings.protectionAppsHint,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (apps.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nexoraSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nexoraBorder),
              ),
              child: Text(
                strings.protectionAppsNone,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            for (final app in _sortedApps()) ...[
              NexoraCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: ntPadSmall,
                  vertical: 8,
                ),
                onTap: () => _openAppDetail(context, app),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.label.isEmpty ? app.packageName : app.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${app.grantedPermissions.length} ${strings.appPermGranted} '
                            '· ${app.dangerousPermissions.length} ${strings.appPermRequestedOnly}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ntGapSmall),
                    LevelBadge(
                      level: classifyAppRisk(app),
                      label: _riskLabel(app),
                      compact: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  List<AppRisk> _sortedApps() {
    final list = [...apps];
    list.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return list;
  }

  String _riskLabel(AppRisk app) => switch (classifyAppRisk(app)) {
    AppRiskLevel.safe => strings.riskSafe,
    AppRiskLevel.attention => strings.riskAttention,
    AppRiskLevel.suspicious => strings.riskSuspicious,
    AppRiskLevel.critical => strings.riskCritical,
  };

  void _openAppDetail(BuildContext ctx, AppRisk app) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) =>
            NexoraAppDetailScreen(app: app, strings: strings, onOpenApp: onOpenApp),
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  const _NetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: nexoraSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: nexoraBorder),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: nexoraGoldLight,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    ),
  );
}
