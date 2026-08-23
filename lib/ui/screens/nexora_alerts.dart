/// "Alertas" — lista los [Finding] reales del último veredicto (mismo
/// motor de reglas que usa el resto de la app), con filtro por severidad.
/// Reusa [FindingCard] para no duplicar el texto/las recomendaciones que
/// ya arma `AppStrings`.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class NexoraAlertsScreen extends StatefulWidget {
  const NexoraAlertsScreen({
    super.key,
    required this.verdict,
    required this.strings,
  });

  final Verdict? verdict;
  final AppStrings strings;

  @override
  State<NexoraAlertsScreen> createState() => _NexoraAlertsScreenState();
}

enum _Filter { all, critical, warning }

class _NexoraAlertsScreenState extends State<NexoraAlertsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final findings = widget.verdict?.findings ?? const <Finding>[];
    final filtered = switch (_filter) {
      _Filter.all => findings,
      _Filter.critical =>
        findings.where((f) => f.severity == Severity.critical).toList(),
      _Filter.warning =>
        findings.where((f) => f.severity == Severity.warning).toList(),
    };

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Alertas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (findings.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: nexoraWine,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${findings.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Críticas',
                  selected: _filter == _Filter.critical,
                  onTap: () => setState(() => _filter = _Filter.critical),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Advertencias',
                  selected: _filter == _Filter.warning,
                  onTap: () => setState(() => _filter = _Filter.warning),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.white24,
                            size: 44,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            findings.isEmpty
                                ? 'Sin alertas activas. Todo tranquilo.'
                                : 'No hay alertas en esta categoría.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => FindingCard(
                      finding: filtered[i],
                      strings: widget.strings,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? nexoraGold : nexoraSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? nexoraGold : nexoraBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? nexoraBackground : Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    ),
  );
}
