/// "Análisis Rápido" — dispara el mismo [CaptureService] que usa el resto
/// de la app (no es una animación decorativa: `onRefresh` recolecta datos
/// reales del dispositivo) y muestra el resultado por categoría.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../nexora_logo.dart';
import '../theme.dart';

class NexoraQuickScanScreen extends StatefulWidget {
  const NexoraQuickScanScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.loading,
    required this.onRefresh,
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  State<NexoraQuickScanScreen> createState() => _NexoraQuickScanScreenState();
}

class _NexoraQuickScanScreenState extends State<NexoraQuickScanScreen> {
  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final verdict = widget.verdict;
    final color = verdict == null
        ? nexoraBlue
        : severityColor(verdict.severity);

    final rows = <(String, String, Severity)>[
      if (snapshot != null) ...[
        (
          'Apps instaladas',
          '${snapshot.apps.length} analizadas',
          snapshot.apps.any((a) => a.severity == Severity.critical)
              ? Severity.critical
              : snapshot.apps.any((a) => a.severity == Severity.warning)
              ? Severity.warning
              : Severity.normal,
        ),
        (
          'Red y conexiones',
          snapshot.network.connected
              ? snapshot.network.transport
              : 'Sin conexión',
          snapshot.network.vpnActive ? Severity.normal : Severity.warning,
        ),
        (
          'Almacenamiento',
          '${(snapshot.storage.freeBytes / (snapshot.storage.totalBytes == 0 ? 1 : snapshot.storage.totalBytes) * 100).toStringAsFixed(0)}% libre',
          Severity.normal,
        ),
        (
          'Batería',
          '${snapshot.battery.levelPercent}% · ${snapshot.battery.healthLabel}',
          snapshot.battery.healthy ? Severity.normal : Severity.warning,
        ),
        if (verdict != null)
          (
            'Amenazas conocidas',
            '${verdict.findings.length} hallazgos',
            verdict.severity,
          ),
      ],
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Center(
            child: Text(
              'Análisis Rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: widget.loading ? null : 1,
                      strokeWidth: 10,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const NexoraLogo(size: 92, showRing: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              widget.loading
                  ? 'Escaneando dispositivo…'
                  : 'Último análisis completo',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: nexoraSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: nexoraBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  ListTile(
                    dense: true,
                    title: Text(
                      rows[i].$1,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      rows[i].$2,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    trailing: _StatusChip(severity: rows[i].$3),
                  ),
                  if (i != rows.length - 1)
                    const Divider(height: 1, color: nexoraBorder),
                ],
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Todavía no hay datos. Iniciá el análisis.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.loading ? nexoraWine : nexoraGold,
                foregroundColor: widget.loading
                    ? Colors.white
                    : nexoraBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: widget.loading ? null : widget.onRefresh,
              child: Text(
                widget.loading ? 'ANALIZANDO…' : 'INICIAR ANÁLISIS',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.severity});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final label = switch (severity) {
      Severity.normal => 'Seguro',
      Severity.warning => 'Atención',
      Severity.critical => 'Riesgo',
    };
    final color = severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
