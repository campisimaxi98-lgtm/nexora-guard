/// Tests de widget de las pantallas del rediseño v2 (FASES 7-10):
/// Gráficas, Perfil, Premium y Nexora AI.
///
/// Mismo contrato que el resto de la suite: las pantallas muestran datos
/// REALES y son honestas — el estado premium no se simula y los diálogos
/// de pagos dicen "próximamente" cuando no hay proveedor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/history_store.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/core/subscription.dart';
import 'package:nexora_guard/ui/screens/nexora_bot.dart';
import 'package:nexora_guard/ui/screens/nexora_charts.dart';
import 'package:nexora_guard/ui/screens/nexora_premium.dart';
import 'package:nexora_guard/ui/screens/nexora_profile.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';
import 'subscription_test.dart' show FakeProvider;

Verdict verdictWith(List<Finding> findings, {Severity severity = Severity.normal}) =>
    Verdict(severity: severity, score: 42, findings: findings);

Future<void> tallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('Gráficas (FASE 7)', () {
    testWidgets('sin historial lo dice honesto', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraChartsScreen(
              snapshot: buildSnapshot(),
              history: const [],
              strings: const AppStrings(AppLang.es),
            ),
          ),
        ),
      );
      expect(find.text('Gráficas'), findsOneWidget);
      expect(
        find.textContaining('Todavía no hay historial'),
        findsOneWidget,
      );
      // La dona usa el almacenamiento REAL del snapshot (50 % libre).
      expect(find.text('Libre'), findsWidgets);
    });

    testWidgets('con historial grafica la serie y nombra las últimas capturas', (
      tester,
    ) async {
      await tallSurface(tester);
      final history = [
        for (var i = 0; i < 3; i++)
          HistoryRow(
            timestampMillis: 1700000000000 + i * 60000,
            severity: Severity.normal,
            score: 10 + i,
            memAvailablePct: 50,
            storageFreePct: 50,
            riskyApps: 0,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraChartsScreen(
              snapshot: buildSnapshot(),
              history: history,
              strings: const AppStrings(AppLang.es),
            ),
          ),
        ),
      );
      expect(find.text('últimas 3 capturas'), findsOneWidget);
      expect(find.text('Temperatura de batería'), findsOneWidget);
      expect(find.text('Puntaje del veredicto'), findsOneWidget);
      expect(find.textContaining('Todavía no hay historial'), findsNothing);
    });
  });

  group('Perfil (FASE 8)', () {
    Widget host({bool premium = false}) {
      return MaterialApp(
        home: Scaffold(
          body: NexoraProfileScreen(
            strings: const AppStrings(AppLang.es),
            subscription: premium
                ? NexoraSubscriptionService(provider: FakeProvider())
                : NexoraSubscriptionService(),
            onOpenLegacy: (_, _) {},
            onRestart: () {},
            snapshot: buildSnapshot(),
            verdict: verdictWith(const []),
            onOpenPremium: () {},
          ),
        ),
      );
    }

    testWidgets('valida el nombre y el usuario con mensajes honestos', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(host());

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('BASIC'), findsOneWidget);

      // El perfil precarga una identidad real: primero se vacía el campo.
      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), '');
      await tester.enterText(find.widgetWithText(TextField, 'Usuario'), '');
      await tester.pump();

      // Guardar con identidad vacía: errores de validación reales.
      final save = find.widgetWithText(FilledButton, 'GUARDAR');
      await tester.ensureVisible(save);
      await tester.pump();
      await tester.tap(save);
      await tester.pump();
      expect(find.text('El nombre no puede quedar vacío.'), findsOneWidget);
      expect(
        find.textContaining('Usuario inválido'),
        findsOneWidget,
      );
    });

    testWidgets('guarda una identidad válida', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(host());

      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Ada');
      await tester.enterText(find.widgetWithText(TextField, 'Usuario'), 'ada');
      await tester.tap(find.widgetWithText(FilledButton, 'GUARDAR'));
      await tester.pump();

      // Confirmación al guardar (snackbar) y sin errores de validación.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('El nombre no puede quedar vacío.'), findsNothing);
    });
  });

  group('Premium (FASE 10)', () {
    Widget host(NexoraSubscriptionService service) => MaterialApp(
      home: NexoraPremiumScreen(
        strings: const AppStrings(AppLang.es),
        subscription: service,
      ),
    );

    testWidgets('sin proveedor: muestra "próximamente", jamás una compra', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(host(NexoraSubscriptionService()));

      expect(find.text('\$10.000 ARS'), findsOneWidget);
      expect(find.text('BASIC'), findsOneWidget);
      expect(find.text('Incluye'), findsOneWidget);

      // Comprar con el proveedor por defecto (sin configurar) abre el
      // diálogo honesto de "próximamente".
      final cta = find.widgetWithText(FilledButton, 'PASSAR A PROFESSIONAL');
      await tester.ensureVisible(cta);
      await tester.pump();
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Próximamente'), findsWidgets);
      expect(
        find.textContaining('Los pagos reales se habilitarán'),
        findsWidgets,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pump();
    });

    testWidgets('con suscripción activa lo confirma sin inventar', (
      tester,
    ) async {
      await tallSurface(tester);
      final service = NexoraSubscriptionService(provider: FakeProvider());
      await service.startPremium();
      expect(service.isPremium, isTrue);

      await tester.pumpWidget(host(service));
      expect(find.text('PROFESSIONAL'), findsWidgets);
      expect(
        find.textContaining('Ya tenés NEXORA PROFESSIONAL activo'),
        findsOneWidget,
      );
      expect(find.text('Próximamente'), findsNothing);
    });
  });

  group('Nexora AI (FASE 9)', () {
    Widget host({List<AppRisk> apps = const []}) => MaterialApp(
      home: NexoraBotScreen(
        strings: const AppStrings(AppLang.es),
        snapshot: buildSnapshot(apps: apps),
        verdict: verdictWith(const [
          Finding(id: 'storage-low', severity: Severity.warning),
        ]),
      ),
    );

    testWidgets('arranca con saludo, nota honesta y sugerencias reales', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(host());

      expect(find.text('¿En qué puedo ayudarte?'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(5));
      // La nota honesta: el asistente no es un veredicto definitivo.
      expect(find.textContaining('Basado solo en señales locales'), findsWidgets);
    });

    testWidgets('responde a una sugerencia con datos reales', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(host());

      final textsBefore = tester.widgetList(find.byType(Text)).length;
      await tester.tap(find.byType(ActionChip).first);
      await tester.pump();

      // Pensando: los chips se deshabilitan mientras se compone la respuesta.
      expect(
        tester.widget<ActionChip>(find.byType(ActionChip).first).onPressed,
        isNull,
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      // Respuesta nueva en el hilo + el mensaje del usuario.
      expect(
        tester.widgetList(find.byType(Text)).length,
        greaterThan(textsBefore + 1),
      );
      expect(
        tester.widget<ActionChip>(find.byType(ActionChip).first).onPressed,
        isNotNull,
      );
    });
  });
}