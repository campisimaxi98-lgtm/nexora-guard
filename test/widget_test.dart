import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';
import 'package:nexora_guard/main.dart';

/// Crea un AuthStore con sesión ya abierta sobre un directorio temporal.
/// Toda la API del store es síncrona: no hace falta runAsync en testWidgets.
AuthStore loggedInStore() {
  final dir = Directory.systemTemp.createTempSync('nexora-widget-auth');
  final store = AuthStore(dir)
    ..load()
    ..register('tester@nexora.dev', 'secreta1');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return store;
}

void main() {
  testWidgets('la app arranca y degrada con elegancia sin canal nativo', (
    tester,
  ) async {
    // En el entorno de test no hay MethodChannel nativo: el puente debe
    // degradar a un snapshot neutro sin crashear (MissingPluginException
    // capturada en PlatformCollectors).
    await tester.pumpWidget(NexoraApp(authStore: loggedInStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nexora'), findsOneWidget);
    // Con snapshot neutro el veredicto existe. Desde v0.8.0 el modo por
    // defecto es 'simple': 3 pestañas (Resumen, Señaladas y Configuración).
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(3));
  });

  testWidgets('autodetecta el idioma del equipo y el menú permite cambiarlo', (
    tester,
  ) async {
    await tester.pumpWidget(NexoraApp(authStore: loggedInStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Idioma automático: el entorno de test corre en en_US, así que arranca
    // en inglés (no en español).
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Resumen'), findsNothing);

    // El menú de idioma permite forzar español. Se usan pumps acotados en
    // vez de pumpAndSettle: el checkmark del menú anima de forma continua y
    // haría que pumpAndSettle nunca "asiente".
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // El texto del ítem va alineado a la derecha; se pulsa el ítem completo.
    await tester.tap(
      find
          .ancestor(
            of: find.text('Español').last,
            matching: find.byType(InkWell),
          )
          .first,
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Summary'), findsNothing);
  });

  testWidgets('sin sesión abierta muestra la puerta de cuenta local', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('nexora-auth-gate');
    final store = AuthStore(dir)..load();
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(NexoraApp(authStore: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    // pumps acotados (los anillos de fondo animan en bucle continuo).

    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('G U A R D'), findsOneWidget);
    // El entorno corre en en_US: textos en inglés.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    // La app todavía NO está visible detrás de la puerta.
    expect(find.byType(TabBar), findsNothing);

    // Crear la cuenta desde la UI abre la app (operación síncrona local).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address').first,
      'nuevo@nexora.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password').first,
      'secreta1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repeat password').first,
      'secreta1',
    );
    final createButton = find.widgetWithText(FilledButton, 'Create my account');
    await tester.ensureVisible(createButton);
    await tester.pump();
    await tester.tap(createButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets(
    'con cuenta existente el modo inicial es iniciar sesión, y volver a entrar funciona',
    (tester) async {
      final store = loggedInStore();
      // Cerrar la sesión manualmente: queda cuenta pero sin sesión abierta.
      store.logout();

      await tester.pumpWidget(NexoraApp(authStore: store));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address').first,
        'tester@nexora.dev',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password').first,
        'secreta1',
      );
      final enterButton = find.widgetWithText(FilledButton, 'Enter');
      await tester.ensureVisible(enterButton);
      await tester.pump();
      await tester.tap(enterButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(TabBar), findsOneWidget);
    },
  );
}
