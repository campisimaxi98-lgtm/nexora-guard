/// Dashboard ("Inicio") — resumen visual del estado real del dispositivo.
///
/// El "Nivel de Protección" y su % son una traducción amigable del
/// [Verdict.severity] real que calcula `rule_engine.dart` (no un dato
/// inventado aparte): severidad normal/precaución/crítica se expresa como
/// un porcentaje indicativo, igual que un semáforo con número al lado.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../nexora_logo.dart';
import '../theme.dart';
import 'nexora_bot.dart';

(int, String) protectionGauge(Severity s) => switch (s) {
  Severity.normal => (96, 'ÓPTIMO'),
  Severity.warning => (62, 'PRECAUCIÓN'),
  Severity.critical => (28, 'EN RIESGO'),
};

class NexoraDashboardScreen extends StatelessWidget {
  const NexoraDashboardScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.history,
    required this.loading,
    required this.onRefresh,
    required this.onOpenTab,
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final List<dynamic> history; // List<HistoryRow>, ver core/history_store.dart
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(int tabIndex) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final (percent, label) = protectionGauge(verdict.severity);
    final color = severityColor(verdict.severity);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: nexoraGold,
        backgroundColor: nexoraSurfaceRaised,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Hola! 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        loading ? 'Analizando…' : 'Todo está bajo control',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const NexoraLogo(size: 46, showRing: false),
              ],
            ),
            const SizedBox(height: 18),

            // --- Tarjeta de nivel de protección ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [nexoraSurfaceRaised, nexoraSurface],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: nexoraBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel de Protección',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: nexoraGoldLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --- Grilla de accesos rápidos ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _QuickAction(
                  icon: Icons.bolt,
                  label: 'Análisis Rápido',
                  sublabel: 'Escanear dispositivo',
                  onTap: () => onOpenTab(1),
                ),
                _QuickAction(
                  icon: Icons.public,
                  label: 'Protección Web',
                  sublabel: 'Navegación segura',
                  onTap: () => onOpenTab(2),
                ),
                _QuickAction(
                  icon: Icons.apps,
                  label: 'Análisis de Apps',
                  sublabel: 'Revisar aplicaciones',
                  onTap: () => onOpenTab(3),
                ),
                _QuickAction(
                  icon: Icons.shield_outlined,
                  label: 'Riesgos',
                  sublabel: '${verdict.findings.length} hallazgos',
                  onTap: () => onOpenTab(3),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenTab(3),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _RecentActivity(history: history, verdict: verdict),

            const SizedBox(height: 18),
            _NexoraBotCard(),
          ],
        ),
      ),
    );
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
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: nexoraSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nexoraBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: nexoraGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: nexoraGoldLight, size: 20),
          ),
          const SizedBox(width: 10),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.history, required this.verdict});

  final List<dynamic> history;
  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: nexoraSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: nexoraBorder),
        ),
        child: const Text(
          'Todavía no hay capturas registradas. Tirá hacia abajo para '
          'analizar el dispositivo por primera vez.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }
    final rows = history.length > 4
        ? history.sublist(history.length - 4)
        : history;
    final reversed = rows.reversed.toList();
    return Container(
      decoration: BoxDecoration(
        color: nexoraSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nexoraBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < reversed.length; i++) ...[
            _ActivityRow(row: reversed[i]),
            if (i != reversed.length - 1)
              const Divider(height: 1, color: nexoraBorder),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.row});

  final dynamic row; // HistoryRow

  @override
  Widget build(BuildContext context) {
    final Severity severity = row.severity as Severity;
    final int ts = row.timestampMillis as int;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    String two(int v) => v.toString().padLeft(2, '0');
    final label = switch (severity) {
      Severity.normal => 'Análisis completado',
      Severity.warning => 'Se detectaron precauciones',
      Severity.critical => 'Riesgo alto detectado',
    };
    return ListTile(
      dense: true,
      leading: Icon(
        switch (severity) {
          Severity.normal => Icons.check_circle,
          Severity.warning => Icons.warning_amber_rounded,
          Severity.critical => Icons.error,
        },
        color: severityColor(severity),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
      ),
      subtitle: Text(
        '${two(dt.hour)}:${two(dt.minute)} · score ${row.score}',
        style: const TextStyle(color: Colors.white38, fontSize: 11.5),
      ),
    );
  }
}

class _NexoraBotCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NexoraBotScreen()),
    ),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: nexoraWine.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nexoraBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: nexoraGold,
            child: Icon(Icons.smart_toy, color: nexoraBackground),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexora',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Preguntá sobre phishing y seguridad digital',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    ),
  );
}
