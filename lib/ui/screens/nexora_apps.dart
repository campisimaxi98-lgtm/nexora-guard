/// Apps (FASE 5) — la auditoría por app reencuadrada en el sistema 4 niveles.
///
/// Lista compacta agrupada por [AppRiskLevel] (SEGURO/ATENCIÓN/SOSPECHOSO/
/// CRÍTICO) con búsqueda, y un detalle con permisos CONCEDIDOS vs solo
/// solicitados, explicación de cada permiso y accesos reales a los Ajustes
/// del sistema. Reglas de honestidad:
/// - La clasificación usa [classifyAppRisk] (evidencia observable, jamás
///   "malware" sin prueba).
/// - NEXORA no revoca permisos ni lo simula: el botón abre la ficha real de
///   la app, donde el SO sí permite gestionarlos.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/app_risk_level.dart';
import '../../core/models.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class NexoraAppsScreen extends StatefulWidget {
  const NexoraAppsScreen({
    super.key,
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.usageAccessGranted = false,
    this.onOpenApp,
    this.onGrantUsageAccess,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;
  final bool usageAccessGranted;
  final void Function(String packageName)? onOpenApp;
  final VoidCallback? onGrantUsageAccess;

  @override
  State<NexoraAppsScreen> createState() => _NexoraAppsScreenState();
}

class _NexoraAppsScreenState extends State<NexoraAppsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    if (!widget.auditSupported) {
      return Padding(
        padding: const EdgeInsets.all(ntPad),
        child: Text(strings.appsUnsupported),
      );
    }

    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.apps
        : widget.apps
              .where(
                (a) =>
                    a.label.toLowerCase().contains(q) ||
                    a.packageName.toLowerCase().contains(q),
              )
              .toList();

    final groups = <AppRiskLevel, List<AppRisk>>{
      for (final level in AppRiskLevel.values) level: <AppRisk>[],
    };
    for (final app in visible) {
      groups[classifyAppRisk(app)]!.add(app);
    }
    // Dentro de cada grupo domina el riesgo real, luego el nombre.
    for (final list in groups.values) {
      list.sort(
        (a, b) => b.riskScore.compareTo(a.riskScore) != 0
            ? b.riskScore.compareTo(a.riskScore)
            : a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(ntPad, 10, ntPad, 28),
      children: [
        // Resumen honesto + CTA real (acceso de uso) si hace falta.
        NexoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeaderRow(icon: Icons.apps, title: strings.appsTitle),
              const SizedBox(height: ntGapSmall),
              ValueRow(
                icon: Icons.work_outline,
                label: strings.appsTotal,
                value: '${widget.apps.length}',
                color: nexoraBlue,
              ),
              ValueRow(
                icon: Icons.flag_outlined,
                label: strings.appsRiskyCount,
                value: '${widget.apps.where((a) => classifyAppRisk(a) != AppRiskLevel.safe).length}',
                color: nexoraOrange,
              ),
              const SizedBox(height: ntGapSmall),
              Text(strings.appsHonestyNote, style: Theme.of(context).textTheme.bodySmall),
              if (!widget.usageAccessGranted && widget.onGrantUsageAccess != null) ...[
                const SizedBox(height: 2),
                Text(
                  strings.appsUsageNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: nexoraGoldLight),
                    icon: const Icon(Icons.timelapse, size: 16),
                    label: Text(strings.appsUsageGrant),
                    onPressed: widget.onGrantUsageAccess,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ntGap),
        // Búsqueda: encontrar una app por su nombre no debería ser una odisea.
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: strings.appSearch,
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            filled: true,
            fillColor: nexoraSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ntRadiusSmall),
              borderSide: const BorderSide(color: nexoraBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ntRadiusSmall),
              borderSide: const BorderSide(color: nexoraBorder),
            ),
          ),
        ),
        const SizedBox(height: ntGap),

        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(strings.appSearchNone)),
          )
        else
          for (final level in AppRiskLevel.values)
            if (groups[level]!.isNotEmpty) ...[
              _LevelSection(
                level: level,
                label: _levelTitle(strings, level),
                apps: groups[level]!,
                strings: strings,
                onOpenDetail: _openDetail,
              ),
              const SizedBox(height: ntGap),
            ],
      ],
    );
  }

  String _levelTitle(AppStrings s, AppRiskLevel level) => switch (level) {
    AppRiskLevel.safe => s.riskSafe,
    AppRiskLevel.attention => s.riskAttention,
    AppRiskLevel.suspicious => s.riskSuspicious,
    AppRiskLevel.critical => s.riskCritical,
  };

  void _openDetail(AppRisk app) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NexoraAppDetailScreen(
      app: app,
      strings: widget.strings,
      onOpenApp: widget.onOpenApp,
    )));
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({
    required this.level,
    required this.label,
    required this.apps,
    required this.strings,
    required this.onOpenDetail,
  });

  final AppRiskLevel level;
  final String label;
  final List<AppRisk> apps;
  final AppStrings strings;
  final void Function(AppRisk app) onOpenDetail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          LevelBadge(level: level, label: label),
          const Spacer(),
          Text(
            '${apps.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      const SizedBox(height: ntGapSmall),
      ...apps.map(
        (app) => Padding(
          padding: const EdgeInsets.only(bottom: ntGapSmall),
          child: _AppRow(app: app, strings: strings, onTap: () => onOpenDetail(app)),
        ),
      ),
    ],
  );
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.strings,
    required this.onTap,
  });

  final AppRisk app;
  final AppStrings strings;
  final VoidCallback onTap;

  Uint8List? _decodeIcon() {
    if (app.iconBase64.isEmpty) return null;
    try {
      return base64Decode(app.iconBase64);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = classifyAppRisk(app);
    final icon = _decodeIcon();
    return NexoraCard(
      padding: const EdgeInsets.symmetric(horizontal: ntPadSmall, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                icon,
                width: 34,
                height: 34,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const _AppFallbackIcon(),
              ),
            )
          else
            const _AppFallbackIcon(),
          const SizedBox(width: ntGapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  app.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: ntGapSmall),
          LevelBadge(level: level, label: _label(strings, level), compact: true),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }

  String _label(AppStrings s, AppRiskLevel level) => switch (level) {
    AppRiskLevel.safe => s.riskSafe,
    AppRiskLevel.attention => s.riskAttention,
    AppRiskLevel.suspicious => s.riskSuspicious,
    AppRiskLevel.critical => s.riskCritical,
  };
}

class _AppFallbackIcon extends StatelessWidget {
  const _AppFallbackIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: nexoraSurfaceRaised,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.apps, color: nexoraGoldLight, size: 18),
  );
}

/// Detalle de una app: evidencia, permisos interactivos y accesos reales.
class NexoraAppDetailScreen extends StatelessWidget {
  const NexoraAppDetailScreen({
    super.key,
    required this.app,
    required this.strings,
    this.onOpenApp,
  });

  final AppRisk app;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;

  void _explainPermission(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(
          strings.appPermExplainTitle,
          style: const TextStyle(fontSize: 17),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.permissionLabel(id),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: ntGapSmall),
            Text(strings.aiPermissionExplain(id)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          if (onOpenApp != null)
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(strings.appDetailOpenSettings),
              onPressed: () {
                Navigator.pop(ctx);
                onOpenApp!(app.packageName);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = classifyAppRisk(app);
    final granted = app.grantedPermissions.toSet();
    final requestedOnly = app.dangerousPermissions
        .where((p) => !granted.contains(p))
        .toList();

    return Scaffold(
      backgroundColor: nexoraBackground,
      appBar: AppBar(title: Text(app.label)),
      body: NexoraMaxWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(ntPad, 10, ntPad, 28),
          children: [
            // Encabezado: identidad + nivel de riesgo real.
            NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DecodedIcon(app: app, size: 44),
                      const SizedBox(width: ntGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(app.packageName, style: theme.textTheme.bodySmall),
                            Text(
                              '${strings.appDetailVersion}: ${app.versionName}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      LevelBadge(level: level, label: _levelLabel(strings, level)),
                    ],
                  ),
                  const SizedBox(height: ntGapSmall),
                  Text(
                    strings.appRiskScore(app.riskScore),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (app.foregroundMillis24h >= 0)
                    Text(
                      strings.appUsage(formatUptime(app.foregroundMillis24h)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (app.dataBytes24h >= 0)
                    Text(
                      strings.appDataUsage(formatBytes(app.dataBytes24h)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: ntGap),

            if (app.sideloaded)
              NexoraCard(
                color: nexoraOrange,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: nexoraOrange, size: 20),
                    const SizedBox(width: ntGapSmall),
                    Expanded(child: Text(strings.appDetailSideload)),
                  ],
                ),
              ),
            if (app.sideloaded) const SizedBox(height: ntGap),

            // Vector de espionaje real: capacidades concedidas y activas.
            if (app.activeCapabilities.isNotEmpty) ...[
              NexoraCard(
                color: nexoraRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeaderRow(
                      icon: Icons.gpp_bad,
                      title: strings.appActiveCapsTitle,
                      iconColor: nexoraRed,
                    ),
                    const SizedBox(height: ntGapSmall),
                    for (final f in app.activeCapabilities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 7, color: nexoraRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                strings.flagLabel(f),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ntGap),
            ],

            // Permisos: concedidos primero (lo que de verdad importa).
            NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeaderRow(
                    icon: Icons.shield_outlined,
                    title: strings.appPermsTitle,
                  ),
                  const SizedBox(height: ntGapSmall),
                  if (app.dangerousPermissions.isEmpty)
                    Text(strings.appDetailNoPerms, style: theme.textTheme.bodySmall)
                  else ...[
                    if (granted.isNotEmpty) ...[
                      Text(
                        strings.appDetailPermsGranted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nexoraGoldLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      for (final p in granted)
                        _PermissionRow(
                          label: strings.permissionLabel(p),
                          hint: strings.appPermGranted,
                          emphasized: true,
                          onTap: () => _explainPermission(context, p),
                        ),
                    ],
                    if (requestedOnly.isNotEmpty) ...[
                      const SizedBox(height: ntGapSmall),
                      Text(
                        strings.appDetailPermsRequested,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      for (final p in requestedOnly)
                        _PermissionRow(
                          label: strings.permissionLabel(p),
                          hint: strings.appPermRequestedOnly,
                          emphasized: false,
                          onTap: () => _explainPermission(context, p),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: ntGap),

            // Acción real: abrir la ficha del sistema (sin simular revocación).
            NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.appDetailHonest, style: theme.textTheme.bodySmall),
                  const SizedBox(height: ntGapSmall),
                  if (onOpenApp != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => onOpenApp!(app.packageName),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(strings.appDetailOpenApp),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(AppStrings s, AppRiskLevel level) => switch (level) {
    AppRiskLevel.safe => s.riskSafe,
    AppRiskLevel.attention => s.riskAttention,
    AppRiskLevel.suspicious => s.riskSuspicious,
    AppRiskLevel.critical => s.riskCritical,
  };
}

class _DecodedIcon extends StatelessWidget {
  const _DecodedIcon({required this.app, this.size = 44});

  final AppRisk app;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (app.iconBase64.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(ntRadiusSmall),
          child: Image.memory(
            base64Decode(app.iconBase64),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                Container(
                  width: size,
                  height: size,
                  color: nexoraSurfaceRaised,
                  child: const Icon(Icons.apps, color: nexoraGoldLight),
                ),
          ),
        );
      } on FormatException {
        // cae al ícono genérico.
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: nexoraSurfaceRaised,
        borderRadius: BorderRadius.circular(ntRadiusSmall),
      ),
      child: Icon(Icons.apps, color: nexoraGoldLight, size: size * 0.5),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.hint,
    required this.emphasized,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(ntRadiusSmall),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            emphasized ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: emphasized ? nexoraGold : nexoraBlue,
          ),
          const SizedBox(width: ntGapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    color: emphasized ? nexoraGoldLight : null,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.help_outline, size: 16, color: nexoraBlue),
        ],
      ),
    ),
  );
}