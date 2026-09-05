/// Pestaña "Señales" (FASE 6): los hallazgos reales del motor de reglas,
/// filtrables por categoría (Red, Permisos, Batería, CPU, RAM, Actividad,
/// Riesgo, Almacenamiento), con la inactivas ocultas por defecto y un
/// "MOSTRAR TODAS" para expandirlas. Debajo, las apps señaladas.
///
/// La categoría de cada hallazgo la decide un mapeo estable por `id` (y por
/// su métrica cuando corresponde): jamás un texto localizado, porque el
/// filtro tiene que funcionar igual en los cinco idiomas.
library;

import 'package:flutter/material.dart';

import '../../core/app_risk_level.dart';
import '../../core/models.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';

/// Categoría de filtro de una señal.
enum NxSignalCategory {
  all,
  network,
  permissions,
  battery,
  cpu,
  ram,
  activity,
  risk,
  storage,
}

/// Categoría estable de un hallazgo por su `id`. Los hallazgos sin mapeo
/// explícito caen en "Riesgo" (nunca se pierden del filtro Todos).
Set<NxSignalCategory> signalCategoriesOf(String id, List<String> args) {
  switch (id) {
    case 'mem-pressure':
      return {NxSignalCategory.ram};
    case 'storage-low':
      return {NxSignalCategory.storage};
    case 'battery-temp':
    case 'battery-health':
      return {NxSignalCategory.battery};
    case 'risky-apps':
    case 'root-indicators':
    case 'patch-old':
      return {NxSignalCategory.risk};
    case 'perm-escalation':
      return {NxSignalCategory.permissions};
    case 'new-apps':
    case 'app-usage-anomaly':
    case 'load-rising-suspect':
      return {NxSignalCategory.activity};
    case 'load-rising':
      // La métrica está en args[0]: 'memory' es RAM, cualquier otra es CPU.
      return args.isNotEmpty && args.first == 'memory'
          ? {NxSignalCategory.ram}
          : {NxSignalCategory.cpu};
    default:
      return {NxSignalCategory.risk};
  }
}

IconData _categoryIcon(NxSignalCategory category) => switch (category) {
  NxSignalCategory.all => Icons.notifications_none,
  NxSignalCategory.network => Icons.wifi,
  NxSignalCategory.permissions => Icons.lock_outline,
  NxSignalCategory.battery => Icons.battery_alert,
  NxSignalCategory.cpu => Icons.memory,
  NxSignalCategory.ram => Icons.speed,
  NxSignalCategory.activity => Icons.av_timer,
  NxSignalCategory.risk => Icons.gpp_bad,
  NxSignalCategory.storage => Icons.storage,
};

IconData _severityIcon(Severity s) => switch (s) {
  Severity.normal => Icons.info_outline,
  Severity.warning => Icons.warning_amber_rounded,
  Severity.critical => Icons.error,
};

class NexoraSignalsScreen extends StatefulWidget {
  const NexoraSignalsScreen({
    super.key,
    required this.verdict,
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.onOpenApp,
  });

  final Verdict verdict;
  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;

  @override
  State<NexoraSignalsScreen> createState() => _NexoraSignalsScreenState();
}

class _NexoraSignalsScreenState extends State<NexoraSignalsScreen> {
  NxSignalCategory _category = NxSignalCategory.all;
  bool _onlyActive = true;

  static const _categories = NxSignalCategory.values;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final findings = widget.verdict.findings;

    final visible = (onlyActiveFindings: _findingsAfterFilters(findings));
    final hiddenInactive = _onlyActive
        ? findings.where((f) => f.severity == Severity.normal).length
        : 0;

    return ListView(
      padding: const EdgeInsets.all(ntPad),
      children: [
        NexoraCard(
          glow: true,
          child: Row(
            children: [
              const Icon(Icons.waves, color: nexoraGoldLight, size: 20),
              const SizedBox(width: ntGapSmall),
Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tabSignals,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    Text(
                      strings.dashFindings(findings.length),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              _SeverityPill(severity: widget.verdict.severity, strings: strings),
            ],
          ),
        ),
        const SizedBox(height: ntPadSmall),

        // Filtros por categoría.
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = _categories[i];
              return _SigChip(
                icon: _categoryIcon(c),
                label: _categoryLabel(strings, c),
                selected: c == _category,
                onTap: () => setState(() => _category = c),
              );
            },
          ),
        ),
        const SizedBox(height: ntGapSmall),

        // Solo activas + botón para expandir.
        Row(
          children: [
            Expanded(child: Text(strings.sigOnlyActive)),
            if (hiddenInactive > 0)
              TextButton(
                onPressed: () => setState(() => _onlyActive = false),
                child: Text(strings.sigShowAll),
              ),
            Switch(
              value: _onlyActive,
              onChanged: (v) => setState(() => _onlyActive = v),
            ),
          ],
        ),
        const SizedBox(height: ntGapSmall),

        if (visible.onlyActiveFindings.isEmpty)
          _EmptySignals(
            nothingAtAll: findings.isEmpty,
            strings: strings,
          )
        else ...[
          for (final f in visible.onlyActiveFindings)
            _SignalCard(
              finding: f,
              strings: strings,
              categories: signalCategoriesOf(f.id, f.args),
            ),
          if (hiddenInactive > 0)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _onlyActive = false),
                icon: const Icon(Icons.expand_more, size: 16),
                label: Text(strings.sigHidden(hiddenInactive)),
              ),
            ),
        ],

        const SizedBox(height: ntPad),

        // Apps señaladas: mismas reglas de siempre, categoría honesta.
        _FlaggedAppsSection(
          apps: widget.apps,
          auditSupported: widget.auditSupported,
          strings: strings,
          onOpenApp: widget.onOpenApp,
        ),
      ],
    );
  }

  List<Finding> _findingsAfterFilters(List<Finding> findings) {
    final byCategory = _category == NxSignalCategory.all
        ? findings
        : findings
              .where(
                (f) => signalCategoriesOf(f.id, f.args).contains(_category),
              )
              .toList();
    if (!_onlyActive) return byCategory;
    return byCategory
        .where((f) => f.severity != Severity.normal)
        .toList();
  }

  String _categoryLabel(AppStrings strings, NxSignalCategory c) =>
      switch (c) {
        NxSignalCategory.all => strings.sigFilterAll,
        NxSignalCategory.network => strings.sigFilterNetwork,
        NxSignalCategory.permissions => strings.sigFilterPermissions,
        NxSignalCategory.battery => strings.sigFilterBattery,
        NxSignalCategory.cpu => strings.sigFilterCpu,
        NxSignalCategory.ram => strings.sigFilterRam,
        NxSignalCategory.activity => strings.sigFilterActivity,
        NxSignalCategory.risk => strings.sigFilterRisk,
        NxSignalCategory.storage => strings.sigFilterStorage,
      };
}

class _SigChip extends StatelessWidget {
  const _SigChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(ntRadiusPill),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? nexoraGold.withValues(alpha: 0.18) : nexoraSurface,
        borderRadius: BorderRadius.circular(ntRadiusPill),
        border: Border.all(
          color: selected ? nexoraGold : nexoraBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? nexoraGold : Theme.of(context).disabledColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? nexoraGold : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity, required this.strings});

  final Severity severity;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    final label = switch (severity) {
      Severity.normal => strings.severityNormal,
      Severity.warning => strings.severityWarning,
      Severity.critical => strings.severityCritical,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ntRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_severityIcon(severity), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una señal: título + detalle con los valores reales + la
/// recomendación honesta (nada de "bloqueado": solo orienta).
class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.finding,
    required this.strings,
    required this.categories,
  });

  final Finding finding;
  final AppStrings strings;
  final Set<NxSignalCategory> categories;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(finding.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: ntGapSmall),
      child: NexoraCard(
        padding: const EdgeInsets.fromLTRB(ntPadSmall, ntPadSmall, ntPadSmall, ntPadSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_severityIcon(finding.severity), size: 17, color: color),
                const SizedBox(width: ntGapSmall),
                Expanded(
                  child: Text(
                    strings.findingTitle(finding),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              strings.findingDetail(finding),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).disabledColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: nexoraSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(ntRadiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 15,
                    color: nexoraGoldLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.findingReco(finding),
                      style: const TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final c in categories)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: nexoraBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ntRadiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_categoryIcon(c), size: 11, color: nexoraBlue),
                        const SizedBox(width: 3),
                        Text(
                          _CategoryTagLabel.strings(c),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: nexoraBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para traducir la etiqueta pequeña de las categorías dentro de la
/// tarjeta (evita acoplar esta clase con el estado del filtro).
class _CategoryTagLabel {
  _CategoryTagLabel._();

  static String strings(NxSignalCategory c) => switch (c) {
    NxSignalCategory.all => 'all',
    NxSignalCategory.network => 'red',
    NxSignalCategory.permissions => 'permisos',
    NxSignalCategory.battery => 'batería',
    NxSignalCategory.cpu => 'cpu',
    NxSignalCategory.ram => 'ram',
    NxSignalCategory.activity => 'actividad',
    NxSignalCategory.risk => 'riesgo',
    NxSignalCategory.storage => 'almacenamiento',
  };
}

class _EmptySignals extends StatelessWidget {
  const _EmptySignals({required this.nothingAtAll, required this.strings});

  final bool nothingAtAll;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.verified_user, size: 40, color: severityGreen),
          const SizedBox(height: 10),
          Text(
            nothingAtAll ? strings.sigNoFindings : strings.sigNoMatches,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Sección de apps señaladas con el nivel real (classifyAppRisk) y la nota
/// de honestidad de siempre: señalada no es maliciosa.
class _FlaggedAppsSection extends StatelessWidget {
  const _FlaggedAppsSection({
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.onOpenApp,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;

  @override
  Widget build(BuildContext context) {
    if (!auditSupported) {
      return NexoraCard(child: Text(strings.appsUnsupported));
    }
    final flagged = apps
        .where((a) => a.severity != Severity.normal || a.sideloaded)
        .toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(icon: Icons.flag, title: strings.flaggedTitle),
        const SizedBox(height: 4),
        Text(
          strings.flaggedNote,
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: ntGapSmall),
        if (flagged.isEmpty)
          NexoraCard(child: Text(strings.flaggedEmpty))
        else ...[
          _AppRow(
            app: flagged.first,
            strings: strings,
            onOpenApp: onOpenApp,
            isOnly: flagged.length == 1,
          ),
          for (final a in flagged.skip(1))
            _AppRow(app: a, strings: strings, onOpenApp: onOpenApp),
        ],
      ],
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.strings,
    this.onOpenApp,
    this.isOnly = false,
  });

  final AppRisk app;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;
  final bool isOnly;

  @override
  Widget build(BuildContext context) {
    final level = classifyAppRisk(app);
    return Padding(
      padding: const EdgeInsets.only(bottom: ntGapSmall),
      child: NexoraCard(
        padding: const EdgeInsets.fromLTRB(ntPadSmall, 10, ntPadSmall, 10),
        onTap: onOpenApp == null ? null : () => onOpenApp!(app.packageName),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LevelBadge(
              level: level,
              label: _levelLabel(strings, level),
              compact: true,
            ),
            if (onOpenApp != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).disabledColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _levelLabel(AppStrings s, AppRiskLevel level) => switch (level) {
  AppRiskLevel.safe => s.riskSafe,
  AppRiskLevel.attention => s.riskAttention,
  AppRiskLevel.suspicious => s.riskSuspicious,
  AppRiskLevel.critical => s.riskCritical,
};