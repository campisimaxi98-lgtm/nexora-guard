// Test de integración end-to-end — se ejecuta en un emulador o teléfono:
//   flutter test integration_test
//
// A diferencia de los tests de widget (test/), aquí SÍ hay canal nativo,
// así que ejercita el flujo real: arranque → cuenta local → primera
// captura → pestañas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexora_guard/main.dart';
import 'package:nexora_guard/ui/screens.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arranca, crea cuenta local, captura y muestra las pestañas', (
    tester,
  ) async {
    await tester.pumpWidget(const NexoraApp());
    // La puerta de sesión y el arranque animan en bucle continuo (anillos),
    // así que se usan pumps acotados: pumpAndSettle nunca asentaría acá.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Puerta local: registrar la cuenta del emulador. Los campos se buscan
    // por tipo/índice para que el test sea agnóstico al idioma del sistema.
    if (find.byType(AuthScreen).evaluate().isNotEmpty) {
      final fields = find.byType(TextFormField);
      final count = fields.evaluate().length;
      await tester.enterText(fields.at(0), 'qa@nexora.dev');
      await tester.enterText(fields.at(1), 'secreta1');
      if (count > 2) {
        await tester.enterText(fields.at(2), 'secreta1');
      }
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 800));
    }

    // Si aparece el onboarding (primera vez), completarlo. El idioma ahora se
    // autodetecta, así que se avanza por el botón (FilledButton), no por texto.
    // Desde v0.8.0 son 4 pasos: el último elige la interfaz y NO se toca, para
    // verificar justo eso — que no elegir deja la básica.
    var guard = 0;
    while (find.byType(OnboardingScreen).evaluate().isNotEmpty && guard < 6) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      guard++;
    }

    expect(find.byType(TabBar), findsOneWidget);
    // Sin tocar la elección, queda el modo básico: Resumen, Señaladas y
    // Configuración.
    expect(find.byType(Tab), findsNWidgets(3));
    // La captura real produjo un veredicto con el medidor radial nuevo.
    expect(find.byType(VerdictBanner), findsOneWidget);
    expect(find.text('NEXORA'), findsNothing); // la puerta quedó atrás
  });
}
