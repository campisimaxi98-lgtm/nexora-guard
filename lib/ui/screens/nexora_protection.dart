/// "Protección Web" — estado real de la conexión (transporte, VPN
/// detectada, medida/no medida) más los hallazgos de red que ya calcula
/// `rule_engine.dart`. NEXORA GUARD no implementa un túnel VPN propio: si
/// no hay ninguna VPN activa en el sistema, se lo decimos así en vez de
/// simular una conexión protegida que no existe.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class NexoraProtectionScreen extends StatelessWidget {
  const NexoraProtectionScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.strings,
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final AppStrings strings;

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
          const Text(
            'Protección Web',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
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
                      ? 'Sin datos todavía'
                      : network.connected
                      ? 'Conectado · ${network.transport}'
                      : 'Sin conexión',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  network?.vpnActive == true
                      ? 'VPN detectada en el sistema'
                      : 'Sin VPN activa en el sistema',
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
                  label: 'Bajada',
                  value: network == null
                      ? '—'
                      : '${network.downstreamKbps} kbps',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NetStat(
                  label: 'Subida',
                  value: network == null ? '—' : '${network.upstreamKbps} kbps',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NetStat(
                  label: 'Medida',
                  value: network == null
                      ? '—'
                      : (network.metered ? 'Sí' : 'No'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Hallazgos de red',
            style: TextStyle(
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
              child: const Text(
                'No hay hallazgos de red en el último análisis.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            for (final f in networkFindings)
              FindingCard(finding: f, strings: strings),
        ],
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
