/// Tests de la FASE 4: gráfica central interactiva y dona que navega.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/history_store.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/screens/nexora_dashboard.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';

const _now = 1700000000000; // mismo "ahora" fijo de buildSnapshot()

List<HistoryRow> _history({int count = 6, int stepMinutes = 20}) => [
  for (var i = 0; i < count; i++)
    HistoryRow(
      timestampMillis: _now - i * stepMinutes * 60 * 1000,
      severity: Severity.normal,
      score: 30,
      memAvailablePct: 64 - i,
      storageFreePct: 50,
      riskyApps: i % 3,
      batteryTempC: i.isEven ? 31 : -1,
    ),
];

/// Sostiene las pestañas que el dashboard pide abrir (dona/quick actions).
class _Tabs {
  final List<String> opened = [];
}

Widget _host(Snapshot snapshot, Verdict verdict, List<HistoryRow> history, _Tabs tabs) {
  return MaterialApp(
    home: Scaffold(
      body: NexoraDashboardScreen(
        snapshot: snapshot,
        verdict: verdict,
        history: history,
        strings: const AppStrings(AppLang.es),
        onRefresh: () async {},
        onOpenTab: tabs.opened.add,
      ),
    ),
  );
}

Future<void> tall(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Verdict verdictOk() => const Verdict(
  severity: Severity.normal,
  score: 10,
  findings: [],
);

void main() {
  testWidgets('la gráfica central muestra ventanas, series y la nota honesta de CPU', (
    tester,
  ) async {
    await tall(tester);
    await tester.pumpWidget(
      _host(buildSnapshot(), verdictOk(), _history(), _Tabs()),
    );

    expect(find.text('Tendencia de métricas'), findsOneWidget);
    for (final w in ['1H', '6H', '24H', '7D']) {
      expect(find.text(w), findsWidgets);
    }
    expect(find.text('TODAS'), findsOneWidget);
    expect(find.text('RAM libre'), findsOneWidget);
    expect(
      find.textContaining('La carga de CPU no la expone esta plataforma'),
      findsOneWidget,
    );
  });

  testWidgets('con menos de 2 capturas en el rango lo dice honesto', (tester) async {
    await tall(tester);
    await tester.pumpWidget(
      _host(buildSnapshot(), verdictOk(), [_history()[0]], _Tabs()),
    );
    expect(find.text('Faltan capturas en este rango.'), findsWidgets);
  });

  testWidgets('cambiar ventana y series no rompe y el toque al gráfico es seguro', (
    tester,
  ) async {
    await tall(tester);
    await tester.pumpWidget(
      _host(buildSnapshot(), verdictOk(), _history(), _Tabs()),
    );

    await tester.tap(find.text('1H'));
    await tester.pump();
    await tester.tap(find.text('RAM libre'));
    await tester.pump();

    // Toque sobre el lienzo: crosshair/tooltip sin excepción.
    final chip = tester.getRect(find.text('24H'));
    await tester.tapAt(Offset(chip.center.dx, chip.bottom + 110));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
  });

  testWidgets('la leyenda de la dona navega a la pantalla de red', (tester) async {
    await tall(tester);
    final tabs = _Tabs();
    await tester.pumpWidget(
      _host(buildSnapshot(), verdictOk(), _history(), tabs),
    );

    await tester.tap(find.text('Red activa'));
    await tester.pump();
    expect(tabs.opened, contains('network'));
  });

  testWidgets('tocar un arco de la dona abre la pantalla del área tocada', (
    tester,
  ) async {
    await tall(tester);
    final tabs = _Tabs();

    // 4 apps, 1 con señales: el arco "apps" es el primer segmento (arriba).
    final apps = [
      buildAppRisk(
        packageName: 'com.example.tracker',
        label: 'TrackerX',
        specialFlags: ['accessibility-service'],
      ),
      buildAppRisk(label: 'SafeA'),
      buildAppRisk(label: 'SafeB'),
      buildAppRisk(label: 'SafeC'),
    ];
    await tester.pumpWidget(
      _host(buildSnapshot(apps: apps), verdictOk(), _history(), tabs),
    );

    // El centro de la dona muestra el % real, tappable (FASE 7/8).
    final center = tester.getCenter(find.byKey(const Key('nx_donut_center')));
    // Arco de 12 horas (segmento apps, primero) y arco de las 3 (red).
    await tester.tapAt(Offset(center.dx, center.dy - 56));
    await tester.pump();
    await tester.tapAt(Offset(center.dx + 56, center.dy));
    await tester.pump();

    expect(tabs.opened, contains('apps'));
    expect(tabs.opened, contains('network'));
  });
}