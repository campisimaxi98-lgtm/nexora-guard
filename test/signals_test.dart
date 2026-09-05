/// Tests de la pantalla Señales (FASE 6): filtros por categoría, solo
/// activas/MOSTRAR TODAS, mapeo estable de categorías y apps señaladas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/screens.dart';
import 'package:nexora_guard/ui/strings.dart';

Widget host({
  required Verdict verdict,
  List<AppRisk> apps = const [],
  bool auditSupported = true,
}) => MaterialApp(
  home: Scaffold(
    body: NexoraSignalsScreen(
      verdict: verdict,
      apps: apps,
      auditSupported: auditSupported,
      strings: const AppStrings(AppLang.es),
      onOpenApp: (_) {},
    ),
  ),
);

Verdict mixVerdict() => Verdict(
  severity: Severity.critical,
  score: 14,
  findings: [
    Finding(id: 'mem-pressure', severity: Severity.critical, args: ['12']),
    Finding(id: 'battery-temp', severity: Severity.warning, args: ['42']),
    Finding(id: 'perm-escalation', severity: Severity.warning, args: ['1', 'WhatsApp']),
    Finding(
      id: 'new-apps',
      severity: Severity.normal,
      args: ['1', 'GpsOnly', '0'],
    ),
  ],
);

void main() {
  testWidgets('el mapeo de categorías es estable y honesto', (tester) async {
    final es = const AppStrings(AppLang.es);
    NxSignalCategory s(String id, [List<String> args = const []]) =>
        signalCategoriesOf(id, args).first;

    expect(s('mem-pressure'), NxSignalCategory.ram);
    expect(s('storage-low'), NxSignalCategory.storage);
    expect(s('battery-temp'), NxSignalCategory.battery);
    expect(s('battery-health'), NxSignalCategory.battery);
    expect(s('perm-escalation'), NxSignalCategory.permissions);
    expect(s('new-apps'), NxSignalCategory.activity);
    expect(s('app-usage-anomaly'), NxSignalCategory.activity);
    expect(s('risky-apps'), NxSignalCategory.risk);
    expect(s('root-indicators'), NxSignalCategory.risk);
    expect(s('patch-old'), NxSignalCategory.risk);
    // load-rising depende de la métrica: memory=RAM, disco=CPU.
    expect(s('load-rising', ['memory']), NxSignalCategory.ram);
    expect(s('load-rising', ['storage']), NxSignalCategory.cpu);
    expect(s('desconocida'), NxSignalCategory.risk);
    expect(es, isNotNull);
  });

  testWidgets('lista las señales con título, detalle y recomendación real', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(verdict: mixVerdict()));

    final es = const AppStrings(AppLang.es);
    expect(find.text(es.findingTitle(mixVerdict().findings.first)), findsOneWidget);
    expect(find.textContaining('12 %'), findsWidgets);
    expect(find.text(es.sigFilterAll), findsWidgets);
  });

  testWidgets('filtra por categoría sin romper los demás hallazgos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(verdict: mixVerdict()));
    final es = const AppStrings(AppLang.es);

    await tester.tap(find.text(es.sigFilterBattery));
    await tester.pump();

    expect(find.text(es.findingTitle(mixVerdict().findings[1])), findsOneWidget);
    expect(find.textContaining('Presión de memoria'), findsNothing);
  });

  testWidgets('oculta inactivas por defecto y MOSTRAR TODAS las revela', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(verdict: mixVerdict()));
    final es = const AppStrings(AppLang.es);

    // El hallazgo 'new-apps' es de severidad normal (inactivo): oculto.
    expect(find.textContaining('GpsOnly'), findsNothing);
    await tester.tap(find.text(es.sigShowAll));
    await tester.pump();

    expect(find.textContaining('GpsOnly'), findsOneWidget);
    expect(find.text(es.sigOnlyActive), findsOneWidget);
  });

  testWidgets('app sin señales muestra el estado vacío honesto', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        verdict: const Verdict(
          severity: Severity.normal,
          score: 0,
          findings: [],
        ),
        auditSupported: false,
      ),
    );
    final es = const AppStrings(AppLang.es);
    expect(find.text(es.sigNoFindings), findsOneWidget);
    expect(find.text(es.appsUnsupported), findsOneWidget);
  });

  testWidgets('la sección de apps señaladas lista y permite abrir la ficha', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NexoraSignalsScreen(
            verdict: mixVerdict(),
            apps: [
              AppRisk.fromMap({
                'packageName': 'com.x.spy',
                'label': 'SpyApp',
                'versionName': '1.0',
                'dangerousPermissions': ['READ_SMS'],
                'specialFlags': ['accessibility-service'],
                'sideloaded': true,
              }),
            ],
            auditSupported: true,
            strings: const AppStrings(AppLang.es),
            onOpenApp: opened.add,
          ),
        ),
      ),
    );

    expect(find.text('SpyApp'), findsOneWidget);
    await tester.tap(find.text('SpyApp'));
    expect(opened, ['com.x.spy']);
  });
}