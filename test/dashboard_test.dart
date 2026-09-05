/// Tests de widget del Dashboard (FASE 4).
///
/// Verifican que la pantalla muestra datos REALES del snapshot/veredicto
/// (no textos inventados a mano) y que respeta la honestidad: sin carga de
/// CPU inventada y sin historial vacío simulado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/app_risk_level.dart';
import 'package:nexora_guard/core/history_store.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/screens/nexora_dashboard.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';

Widget host(Snapshot snapshot, Verdict verdict, {List<HistoryRow> history = const []}) {
  return MaterialApp(
    home: Scaffold(
      body: NexoraDashboardScreen(
        snapshot: snapshot,
        verdict: verdict,
        history: history,
        strings: const AppStrings(AppLang.es),
        onRefresh: () async {},
        onOpenTab: (_) {},
      ),
    ),
  );
}

Verdict verdictWith(List<Finding> findings, {Severity severity = Severity.normal}) =>
    Verdict(severity: severity, score: 42, findings: findings);

Future<void> tallSurface(WidgetTester tester) async {
  // El ListView infla solo lo visible: superficie alta para que las
  // secciones inferiores (recursos, apps, actividad) existan en el árbol.
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  test('protectionGauge traduce la severidad real a % y nivel', () {
    expect(protectionGauge(Severity.normal), (96, AppRiskLevel.safe));
    expect(protectionGauge(Severity.warning).$1, 58);
    expect(protectionGauge(Severity.critical), (26, AppRiskLevel.critical));
  });

  testWidgets('muestra el escudo con % y hallazgos reales del veredicto', (
    tester,
  ) async {
    await tallSurface(tester);
    final findings = [
      Finding(id: 'storage-low', severity: Severity.warning),
      Finding(id: 'battery-temp', severity: Severity.warning),
    ];
    await tallSurface(tester);
    await tester.pumpWidget(
      host(buildSnapshot(), verdictWith(findings, severity: Severity.warning)),
    );

    expect(find.text('Nivel de protección'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('PRECAUCIÓN'), findsOneWidget);
    expect(find.text('2 hallazgo(s)'), findsOneWidget);
  });

  testWidgets('las barras de recursos usan los valores del snapshot', (
    tester,
  ) async {
    await tallSurface(tester);
    await tester.pumpWidget(host(buildSnapshot(), verdictWith(const [])));

    // RAM usada 4 GiB de 8 GiB, batería 80 %, temp 30.0 °C.
    expect(find.text('4.0 GB / 8.0 GB'), findsOneWidget);
    expect(find.text('80%'), findsWidgets); // tile del nivel + barra
    expect(find.text('30.0 °C'), findsOneWidget);
    // Red conectada: velocidades en vivo.
    expect(find.text('10000 kbps'), findsOneWidget);
    expect(find.text('5000 kbps'), findsOneWidget);
  });

  testWidgets('la CPU se muestra real: núcleos, sin inventar un porcentaje', (
    tester,
  ) async {
    await tallSurface(tester);
    await tester.pumpWidget(host(buildSnapshot(), verdictWith(const [])));

    expect(find.text('Núcleos'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.textContaining('% de CPU'), findsNothing);
  });

  testWidgets('apps con señales aparecen con su nivel real', (tester) async {
    final apps = [
      buildAppRisk(
        packageName: 'com.example.tracker',
        label: 'TrackerX',
        specialFlags: ['accessibility-service'],
      ),
    ];
    final snapshot = buildSnapshot(apps: apps);
    await tallSurface(tester);
    await tester.pumpWidget(host(snapshot, verdictWith(const [])));

    expect(find.text('TrackerX'), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.text('VER ANÁLISIS'), findsOneWidget);
  });

  testWidgets('sin apps riesgosas lo dice honesto', (tester) async {
    await tallSurface(tester);
    await tester.pumpWidget(host(buildSnapshot(), verdictWith(const [])));
    expect(find.text('Sin apps con señales destacadas'), findsOneWidget);
  });

  testWidgets('historial vacío se comunica, y con filas muestra la última', (
    tester,
  ) async {
    await tallSurface(tester);
    await tester.pumpWidget(host(buildSnapshot(), verdictWith(const [])));
    expect(
      find.textContaining('Todavía no hay capturas'),
      findsOneWidget,
    );

    final history = [
      HistoryRow(
        timestampMillis: 1700000000000,
        severity: Severity.warning,
        score: 42,
        memAvailablePct: 50,
        storageFreePct: 50,
        riskyApps: 1,
      ),
    ];
    await tallSurface(tester);
    await tester.pumpWidget(
      host(buildSnapshot(), verdictWith(const []), history: history),
    );
    expect(find.text('Se detectaron precauciones'), findsOneWidget);
    expect(find.textContaining('riesgo 42'), findsOneWidget);
  });
}
