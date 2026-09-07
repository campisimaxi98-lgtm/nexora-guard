/// Tests FASE 7 — análisis visual: función de salud compuesta (deviceHealth),
/// centro de la dona del dashboard con % real + sensores, estadísticas y
/// variación de la gráfica interactiva, y análisis avanzado (onda/área/
/// barras/dispersión) que solo dibuja datos reales del historial.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/history_store.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/screens/nexora_charts.dart';
import 'package:nexora_guard/ui/screens/nexora_dashboard.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';

Verdict verdictOk() => const Verdict(severity: Severity.normal, score: 12, findings: []);
Verdict verdictCritical() =>
    const Verdict(severity: Severity.critical, score: 90, findings: []);

List<HistoryRow> history(int n) => [
  for (var i = 0; i < n; i++)
    HistoryRow(
      timestampMillis: 1700000000000 - (n - 1 - i) * 60000,
      severity: Severity.normal,
      score: 10 + i,
      memAvailablePct: 50,
      storageFreePct: 60,
      riskyApps: 1,
      batteryTempC: 30,
    ),
];

Future<void> tallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 2800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('deviceHealth (salud compuesta real)', () {
    test('usa solo componentes disponibles y cuenta sensores activos', () {
      // Memoria 50% libre, almacenamiento 50% libre, batería 80%,
      // CPU no disponible, red normal → 4 de 5 sensores activos.
      final (h, active) = deviceHealth(buildSnapshot(), verdictOk());
      expect(active, 4, reason: 'mem, almacenamiento, batería y red');
      expect(h, inInclusiveRange(0, 100));
      // Sin CPU: el promedio ponderado queda entre 50% y 100%.
      expect(h, greaterThan(50), reason: 'mem+storage al 50, bat 80, red ok');
    });

    test('penaliza el veredicto crítico (red) bajando la salud', () {
      final (okH, _) = deviceHealth(buildSnapshot(), verdictOk());
      final (critH, _) = deviceHealth(buildSnapshot(), verdictCritical());
      expect(critH, lessThan(okH));
    });

    test('sin memoria ni almacenamiento no se divide por cero', () {
      final snap = buildSnapshot(
        memory: const MemoryInfo(totalBytes: 0, availableBytes: 0, lowMemory: false),
        storage: const StorageInfo(totalBytes: 0, freeBytes: 0, appCacheBytes: 0),
      );
      final (h, active) = deviceHealth(snap, verdictOk());
      expect(h, inInclusiveRange(0, 100));
      expect(active, greaterThanOrEqualTo(1)); // la red siempre cuenta
    });
  });

  group('Dona del dashboard — centro real', () {
    testWidgets('muestra el % de salud compuesta y sensores activos', (tester) async {
      await tallSurface(tester);
      final snap = buildSnapshot();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraDashboardScreen(
              snapshot: snap,
              verdict: verdictOk(),
              history: const [],
              strings: const AppStrings(AppLang.es),
            ),
          ),
        ),
      );
      final (h, active) = deviceHealth(snap, verdictOk());
      expect(find.text('$h%'), findsWidgets);
      expect(find.text('SALUD $active/5 sensores'), findsOneWidget);
    });
  });

  group('Gráfica interactiva — estadísticas y variación', () {
    testWidgets('con historial muestra chips de estadísticas honestos', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraDashboardScreen(
              snapshot: buildSnapshot(),
              verdict: verdictOk(),
              history: history(3),
              strings: const AppStrings(AppLang.es),
            ),
          ),
        ),
      );
      // Se selecciona una serie concreta para ver máx/mín/prom de la ventana.
      final memChip = find.text('RAM libre');
      await tester.ensureVisible(memChip);
      await tester.pump();
      await tester.tap(memChip);
      await tester.pump();
      expect(find.text('MÁX'), findsOneWidget);
      expect(find.text('MÍN'), findsOneWidget);
      expect(find.text('PROM'), findsOneWidget);
    });

    testWidgets('vista "todas" muestra la variación vs la captura inicial', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraDashboardScreen(
              snapshot: buildSnapshot(),
              verdict: verdictOk(),
              history: history(3),
              strings: const AppStrings(AppLang.es),
            ),
          ),
        ),
      );
      // El puntaje sube de 10 a 12 → variación +2 (delta de cache se resta 0).
      expect(find.textContaining('vs inicial'), findsOneWidget);
    });
  });

  group('Análisis avanzado (FASE 7)', () {
    Widget host({List<HistoryRow> rows = const []}) => MaterialApp(
      home: Scaffold(
        body: NexoraChartsScreen(
          snapshot: buildSnapshot(),
          history: rows,
          strings: const AppStrings(AppLang.es),
        ),
      ),
    );

    testWidgets('sin historial pide capturas con honestidad', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(host());
      expect(find.text('Análisis avanzado'), findsNothing);
      expect(
        find.textContaining('Hacé al menos 2 capturas'),
        findsOneWidget,
      );
    });

    testWidgets('con historial muestra las cuatro vistas animadas', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(host(rows: history(4)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Análisis avanzado'), findsOneWidget);
      expect(find.text('Onda'), findsOneWidget);
      expect(find.text('Área'), findsOneWidget);
      expect(find.text('Barras'), findsOneWidget);
      expect(find.text('Dispersión'), findsOneWidget);
    });
  });
}
