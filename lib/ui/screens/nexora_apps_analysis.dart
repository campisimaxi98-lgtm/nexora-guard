/// "Análisis de Apps" — lista real de `Snapshot.apps` (AppRisk), agrupada
/// por severidad. La dona se dibuja con [CustomPainter] (sin paquetes de
/// gráficos, siguiendo la regla de cero dependencias externas del proyecto).
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../theme.dart';

class NexoraAppsAnalysisScreen extends StatelessWidget {
  const NexoraAppsAnalysisScreen({
    super.key,
    required this.snapshot,
    required this.onOpenApp,
  });

  final Snapshot? snapshot;
  final void Function(String packageName) onOpenApp;

  @override
  Widget build(BuildContext context) {
    final apps = snapshot?.apps ?? const <AppRisk>[];
    final safe = apps.where((a) => a.severity == Severity.normal).length;
    final warn = apps.where((a) => a.severity == Severity.warning).length;
    final risky = apps.where((a) => a.severity == Severity.critical).length;

    final sorted = [...apps]
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Análisis de Apps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: CustomPaint(
                painter: _DonutPainter(safe: safe, warn: warn, risky: risky),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${apps.length}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Apps\nanalizadas',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _LegendStat(
                  color: severityColor(Severity.normal),
                  value: safe,
                  label: 'Seguras',
                ),
              ),
              Expanded(
                child: _LegendStat(
                  color: severityColor(Severity.warning),
                  value: warn,
                  label: 'Advertencias',
                ),
              ),
              Expanded(
                child: _LegendStat(
                  color: severityColor(Severity.critical),
                  value: risky,
                  label: 'Peligrosas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Aplicaciones',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          if (sorted.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nexoraSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nexoraBorder),
              ),
              child: const Text(
                'Todavía no hay apps analizadas. Corré un análisis primero.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: nexoraSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nexoraBorder),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    _AppRow(app: sorted[i], onTap: onOpenApp),
                    if (i != sorted.length - 1)
                      const Divider(height: 1, color: nexoraBorder),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendStat extends StatelessWidget {
  const _LegendStat({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
      ),
    ],
  );
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.onTap});

  final AppRisk app;
  final void Function(String packageName) onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (app.severity) {
      Severity.normal => 'Segura',
      Severity.warning => 'Advertencia',
      Severity.critical => 'Peligrosa',
    };
    Widget leading;
    if (app.iconBase64.isNotEmpty) {
      try {
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(app.iconBase64),
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        );
      } on FormatException {
        leading = const _AppFallbackIcon();
      }
    } else {
      leading = const _AppFallbackIcon();
    }
    return ListTile(
      dense: true,
      leading: leading,
      title: Text(
        app.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
      ),
      subtitle: app.sideloaded
          ? const Text(
              'Instalada fuera de la tienda',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            )
          : null,
      trailing: Text(
        label,
        style: TextStyle(
          color: severityColor(app.severity),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      onTap: () => onTap(app.packageName),
    );
  }
}

class _AppFallbackIcon extends StatelessWidget {
  const _AppFallbackIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: nexoraSurfaceRaised,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.apps, color: Colors.white38, size: 18),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.safe, required this.warn, required this.risky});

  final int safe;
  final int warn;
  final int risky;

  @override
  void paint(Canvas canvas, Size size) {
    final total = safe + warn + risky;
    final rect = Offset.zero & size;
    const strokeWidth = 18.0;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white10;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 6.28319, false, base);
    if (total == 0) return;

    double start = -1.5708; // -90°
    void drawSlice(int value, Color color) {
      if (value <= 0) return;
      final sweep = (value / total) * 6.28319;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }

    drawSlice(safe, severityColor(Severity.normal));
    drawSlice(warn, severityColor(Severity.warning));
    drawSlice(risky, severityColor(Severity.critical));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.safe != safe ||
      oldDelegate.warn != warn ||
      oldDelegate.risky != risky;
}
