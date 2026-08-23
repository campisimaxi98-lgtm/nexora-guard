/// Tests de los widgets interactivos de v1.0.0: dona táctil, cifra animada,
/// gráfico con scrub y entrada escalonada.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/strings.dart';
import 'package:nexora_guard/ui/widgets.dart';

void main() {
  const strings = AppStrings(AppLang.es);

  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('AnimatedNumber termina en el valor final con sufijo', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AnimatedNumber(42, suffix: '%')));
    await tester.pumpAndSettle();
    expect(find.text('42%'), findsOneWidget);
  });

  testWidgets('StaggerIn revela su hijo tras la cascada', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            StaggerIn(index: 0, child: const Text('uno')),
            StaggerIn(index: 5, child: const Text('dos')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('uno'), findsOneWidget);
    expect(find.text('dos'), findsOneWidget);
  });

  testWidgets('ThreatDonut: total en el centro y selección por leyenda', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ThreatDonut(
          counts: const {Severity.warning: 1, Severity.critical: 1},
          strings: strings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Total de hallazgos en el centro.
    expect(find.text('2'), findsOneWidget);
    expect(find.text(strings.metricSignals), findsOneWidget);

    // Tocar la leyenda selecciona la severidad → porcentaje en el centro.
    // `.first`: al estar seleccionada, el texto también vive en el centro.
    await tester.tap(find.text(strings.severityWarning).first);
    await tester.pumpAndSettle();
    expect(find.text('50 %'), findsOneWidget);
    expect(find.text(strings.severityWarning), findsWidgets);

    // Tocar de nuevo deselecciona y vuelve al total.
    await tester.tap(find.text(strings.severityWarning).first);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('ThreatDonut sin hallazgos muestra el mensaje vacío', (
    tester,
  ) async {
    await tester.pumpWidget(host(ThreatDonut(counts: {}, strings: strings)));
    await tester.pump();
    expect(find.text(strings.donutEmpty), findsOneWidget);
  });

  testWidgets('InteractiveLineChart pinta y sobrevive a un toque de scrub', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 150,
              child: InteractiveLineChart(
                xLabels: const ['01/01 10:00', '01/01 11:00', '01/01 12:00'],
                series: [
                  LineSeries(
                    label: 'RAM',
                    points: const [10, 50, 90],
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = find.byType(InteractiveLineChart);
    await tester.tap(chart);
    await tester.pumpAndSettle();

    // Segundo toque en otro punto cambia el índice sin errores.
    final center = tester.getCenter(chart);
    await tester.tapAt(Offset(center.dx - 60, center.dy));
    await tester.pumpAndSettle();
  });
}
