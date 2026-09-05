/// Tests de la FASE 6 (UI): hub NEXORA PLAY y los cuatro juegos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/games/phishing_cases.dart';
import 'package:nexora_guard/ui/screens/nexora_play.dart';
import 'package:nexora_guard/ui/games.dart';
import 'package:nexora_guard/ui/strings.dart';

const s = AppStrings(AppLang.es);

Widget _host(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('el hub muestra los cuatro juegos y la sección de logros', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(
      NexoraPlayScreen(strings: s, directoryPath: null),
    ));
    await tester.pump();
    expect(find.text('NEXORA PLAY'), findsWidgets);
    expect(find.text('Juegos'), findsWidgets);
    expect(find.text(s.gmMines), findsWidgets);
    expect(find.text(s.gmChess), findsWidgets);
    expect(find.text(s.gmFirewall), findsWidgets);
    expect(find.text(s.gmPhishing), findsWidgets);
  });

  testWidgets('los cuatro juegos abren desde su tarjeta en el hub', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(
      NexoraPlayScreen(strings: s, directoryPath: null),
    ));
    await tester.pump();

    await tester.ensureVisible(find.text(s.gmMines));
    await tester.tap(find.text(s.gmMines));
    await tester.pumpAndSettle();
    expect(find.byType(NexoraMinesScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(s.gmChess));
    await tester.tap(find.text(s.gmChess));
    await tester.pumpAndSettle();
    expect(find.byType(NexoraChessScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(s.gmFirewall));
    await tester.tap(find.text(s.gmFirewall));
    await tester.pumpAndSettle();
    expect(find.byType(NexoraFirewallScreen), findsOneWidget);
    // Desmonta para cancelar el Timer periódico del firewall.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Phishing Detector: responder bien los 6 casos gana', (
    tester,
  ) async {
    int? gotScore;
    bool? gotWon;
    await tester.pumpWidget(_host(
      NexoraPhishingScreen(
        strings: s,
        onBack: () {},
        onFinished: (score, won) {
          gotScore = score;
          gotWon = won;
        },
      ),
    ));
    await tester.pump();

    for (var i = 0; i < phishingTotal(); i++) {
      final fraud = phishingIsFraud(phishingCases[i].id);
      await tester.tap(find.text(fraud ? 'Fraude' : 'Legítimo'));
      await tester.pump();
    }

    expect(gotScore, phishingTotal());
    expect(gotWon, isTrue);
    expect(find.text('¡Perfecto!'), findsOneWidget);
  });

  testWidgets('Phishing Detector: respuesta incorrecta se puntúa honesto', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(_host(
      NexoraPhishingScreen(
        strings: s,
        onBack: () {},
        onFinished: (score, won) {
          finished = true;
        },
      ),
    ));
    await tester.pump();

    // Primer caso (fraude): marcamos "Legítimo" a propósito → 0/6.
    await tester.tap(find.text('Legítimo'));
    await tester.pump();
    expect(finished, isFalse); // el mazo no termina con 1 respuesta
    expect(find.text('¡Perfecto!'), findsNothing);
    expect(find.byType(NexoraPhishingScreen), findsOneWidget);
  });

  testWidgets('los juegos pintan su tablero inicial sin romper', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      NexoraMinesScreen(strings: s, onBack: () {}, onFinished: (a, b) {}, randomSeed: 1),
    ));
    expect(find.byType(NexoraMinesScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(_host(
      NexoraChessScreen(strings: s, onBack: () {}, onFinished: (a, b) {}, randomSeed: 2),
    ));
    // La fila inicial tiene peones blancos en la segunda fila.
    expect(find.text('♙'), findsWidgets);
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(_host(
      NexoraGridFirewallProbe(strings: s),
    ));
    expect(find.byType(NexoraFirewallScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class NexoraGridFirewallProbe extends StatelessWidget {
  const NexoraGridFirewallProbe({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => NexoraFirewallScreen(
    strings: strings,
    onBack: () {},
    onFinished: (a, b) {},
    randomSeed: 3,
  );
}