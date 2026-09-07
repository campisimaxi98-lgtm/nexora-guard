/// Tests FASE 7 — flujos de UI de cuenta: recuperación por código local
/// (4 pasos) y cambio de contraseña desde el perfil. Ambos usan un
/// [AuthStore] real sobre un directorio temporal: nada se simula.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';
import 'package:nexora_guard/ui/screens/auth.dart';
import 'package:nexora_guard/ui/screens/nexora_profile.dart';
import 'package:nexora_guard/ui/strings.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexora-f7-ui');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AuthStore storeWithAccount() {
    final store = AuthStore(dir)..load();
    store.register('cuenta@nexora.dev', 'Secret1@2026', name: 'María', username: 'maria_g');
    return store;
  }

  const strings = AppStrings(AppLang.es);

  testWidgets('RecoveryScreen: email → código local visible → contraseña → ok', (
    tester,
  ) async {
    final store = storeWithAccount();
    await tester.pumpWidget(
      MaterialApp(
        home: RecoveryScreen(
          strings: strings,
          store: store,
          email: 'cuenta@nexora.dev',
          codeGenerator: () => '123456',
        ),
      ),
    );

    // Paso 1: email ya precargado → continuar.
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    // Paso 2: el código local se muestra en pantalla (honesto, sin red).
    expect(find.text('123456'), findsOneWidget);
    expect(find.textContaining('no se envía por correo'), findsWidgets);

    // Paso 3: ingresar el código mostrado y verificar.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de 6 dígitos'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Verificar y continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contraseña'),
      'Nueva123Zeta',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar nueva contraseña'),
      'Nueva123Zeta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    // Paso 4: confirmación y la cuenta queda operable con la nueva clave.
    expect(find.text('¡Listo!'), findsOneWidget);

    // La contraseña restablecida abre sesión de verdad.
    expect(store.login('cuenta@nexora.dev', 'Nueva123Zeta'), AuthResult.ok);
    expect(store.login('cuenta@nexora.dev', 'Secret1@2026'), AuthResult.wrongCredentials);
  });

  testWidgets('RecoveryScreen rechaza un código inválido con honestidad', (
    tester,
  ) async {
    final store = storeWithAccount();
    await tester.pumpWidget(
      MaterialApp(
        home: RecoveryScreen(
          strings: strings,
          store: store,
          email: 'cuenta@nexora.dev',
          codeGenerator: () => '123456',
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de 6 dígitos'),
      '000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Verificar y continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no coincide'), findsOneWidget);
  });

  testWidgets('ChangePasswordScreen: actual incorrecta da error honesto', (
    tester,
  ) async {
    final store = storeWithAccount();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangePasswordScreen(strings: strings, store: store),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'equivocada',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contraseña'),
      'Nueva123Zeta',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar nueva contraseña'),
      'Nueva123Zeta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar contraseña'));
    await tester.pump();
    expect(find.text('La contraseña actual no es correcta.'), findsOneWidget);
  });

  testWidgets('ChangePasswordScreen: claves distintas avisan y no persisten', (
    tester,
  ) async {
    final store = storeWithAccount();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ChangePasswordScreen(strings: strings, store: store),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'Secret1@2026',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contraseña'),
      'Nueva123Zeta',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar nueva contraseña'),
      'otra-cosa',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar contraseña'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    // No se cambió nada: la actual sigue sirviendo.
    expect(store.login('cuenta@nexora.dev', 'Secret1@2026'), AuthResult.ok);
  });
}