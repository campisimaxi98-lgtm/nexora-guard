/// Tests de la pantalla Apps (FASE 5): agrupación 4 niveles por clase real,
/// búsqueda, detalle con permisos interactivos y honestidad (sin revocación
/// simulada).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/screens.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';

Widget host({
  List<AppRisk> apps = const [],
  bool auditSupported = true,
}) => MaterialApp(
  home: Scaffold(
    body: NexoraAppsScreen(
      apps: apps,
      auditSupported: auditSupported,
      strings: const AppStrings(AppLang.es),
      onOpenApp: (_) {},
      onGrantUsageAccess: () {},
    ),
  ),
);

/// Cuatro apps que cubren cada nivel de la escala (por evidencia real).
List<AppRisk> fourApps() => [
  buildAppRisk(packageName: 'com.a.safe', label: 'SafeApp'),
  buildAppRisk(
    packageName: 'com.a.attention',
    label: 'AttentionApp',
    dangerousPermissions: ['CAMERA'],
    grantedPermissions: ['CAMERA'],
  ),
  buildAppRisk(
    packageName: 'com.a.suspicious',
    label: 'SuspiciousApp',
    dangerousPermissions: ['READ_SMS', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION'],
    specialFlags: ['overlay'],
    sideloaded: true,
  ),
  buildAppRisk(
    packageName: 'com.a.critical',
    label: 'CriticalApp',
    specialFlags: ['accessibility-service'],
  ),
];

void main() {
  testWidgets('agrupa por los 4 niveles usando la clasificación real', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(apps: fourApps()));

    expect(find.text('SafeApp'), findsOneWidget);
    expect(find.text('AttentionApp'), findsOneWidget);
    expect(find.text('SuspiciousApp'), findsOneWidget);
    expect(find.text('CriticalApp'), findsOneWidget);

    // Cada etiqueta de nivel aparece al menos una vez (grupo + fila).
    expect(find.text('Crítico'), findsWidgets);
    expect(find.text('Sospechoso'), findsWidgets);
    expect(find.text('Atención'), findsWidgets);
    expect(find.text('Seguro'), findsWidgets);
  });

  testWidgets('auditoría no soportada se comunica con honestidad', (
    tester,
  ) async {
    await tester.pumpWidget(host(auditSupported: false));
    final es = const AppStrings(AppLang.es);
    expect(find.text(es.appsUnsupported), findsOneWidget);
  });

  testWidgets('la búsqueda filtra por nombre', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(apps: fourApps()));
    await tester.enterText(find.byType(TextField), 'critical');
    await tester.pump();

    expect(find.text('CriticalApp'), findsOneWidget);
    expect(find.text('SafeApp'), findsNothing);
  });

  testWidgets('el detalle muestra versión y permisos concedidos vs pedidos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(apps: fourApps()));

    await tester.tap(find.text('AttentionApp'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Versión'), findsOneWidget);
    expect(find.text('Permisos concedidos hoy'), findsOneWidget);
    expect(find.text('Permisos solicitados, no concedidos'), findsNothing);
  });

  testWidgets('tocar un permiso explica qué significa y no simula revocar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(apps: fourApps()));
    await tester.tap(find.text('AttentionApp'));
    await tester.pumpAndSettle();

    // Cámara está concedida en AttentionApp.
    final es = const AppStrings(AppLang.es);
    await tester.tap(find.text(es.permissionLabel('CAMERA')));
    await tester.pumpAndSettle();

    expect(find.text(es.appPermExplainTitle), findsOneWidget);
    // La explicación real de la cámara (no una plantilla vacía).
    expect(find.textContaining('Cámara'), findsWidgets);
    // CTA honesto: abrir ajustes reales, jamás "revoquemos".
    expect(find.text(es.appDetailOpenSettings), findsOneWidget);
  });

  testWidgets('una app crítica muestra su vector activo en el detalle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host(apps: fourApps()));
    await tester.tap(find.text('CriticalApp'));
    await tester.pumpAndSettle();

    final es = const AppStrings(AppLang.es);
    expect(find.text(es.appActiveCapsTitle), findsOneWidget);
    expect(find.text(es.flagLabel('accessibility-service')), findsOneWidget);
  });
}