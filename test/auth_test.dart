/// Tests de la puerta local de cuentas (`core/auth_store.dart`).
///
/// Cubren el ciclo completo registro → sesión → logout → login, los
/// rechazos de entrada inválida, la regla "una cuenta por teléfono" y la
/// degradación elegante ante un archivo corrupto.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';
import 'package:nexora_guard/core/password_recovery.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexora-auth-test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AuthStore freshStore() {
    final store = AuthStore(dir)..load();
    return store;
  }

  test(
    'register crea la cuenta, abre sesión y persiste entre instancias',
    () async {
      final store = freshStore();
      expect(store.register('Maxi@Ejemplo.com', 'Secret1@2026'), AuthResult.ok);
      expect(store.loggedIn, isTrue);
      expect(store.account!.email, 'maxi@ejemplo.com');

      // Otra instancia sobre el mismo directorio retoma sesión y cuenta.
      final reopened = freshStore();
      expect(reopened.loggedIn, isTrue);
      expect(reopened.account!.email, 'maxi@ejemplo.com');
    },
  );

  test('register rechaza email inválido y contraseña débil', () async {
    final store = freshStore();
    expect(
      store.register('no-es-un-correo', 'Secret1@2026'),
      AuthResult.invalidEmail,
    );
    expect(store.register('a@b.co', 'corta'), AuthResult.weakPassword);
    expect(store.account, isNull);
  });

  test('una sola cuenta por teléfono', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'Secret1@2026');
    expect(store.register('dos@nexora.dev', 'Secret2@2026'), AuthResult.emailTaken);
    // La original sigue intacta.
    final other = freshStore();
    expect(other.account!.email, 'uno@nexora.dev');
  });

  test('login valida credenciales contra el hash estirado', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'Secret1@2026');
    store.logout();

    final second = freshStore();
    expect(
      second.login('otro@nexora.dev', 'Secret1@2026'),
      AuthResult.wrongCredentials,
    );
    expect(
      second.login('uno@nexora.dev', 'incorrecta'),
      AuthResult.wrongCredentials,
    );
    expect(second.loggedIn, isFalse);
    expect(second.login('UNO@Nexora.dev ', 'Secret1@2026'), AuthResult.ok);
    expect(second.loggedIn, isTrue);
  });

  test('logout cierra la sesión y conserva la cuenta', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'Secret1@2026');

    final other = freshStore();
    other.logout();

    final reopened = freshStore();
    expect(reopened.loggedIn, isFalse);
    expect(reopened.account, isNotNull);
  });

  test('wipe deja el estado como recién instalado', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'Secret1@2026');
    store.wipe();

    final reopened = freshStore();
    expect(reopened.account, isNull);
    expect(reopened.loggedIn, isFalse);
    // Y se puede registrar de nuevo desde cero.
    expect(reopened.register('nuevo@nexora.dev', 'Secret3@2026'), AuthResult.ok);
  });

  test('archivo corrupto o ajeno degrada a sin cuenta', () async {
    final target = File('${dir.path}/nexora-auth.json');
    target.writeAsStringSync('<esto no es json>');
    final corrupted = freshStore();
    expect(corrupted.account, isNull);

    target.writeAsStringSync(jsonEncode([1, 2]));
    final alien = freshStore();
    expect(alien.account, isNull);
    expect(alien.loggedIn, isFalse);
  });

  test('sin "Recordarme" la sesión dura solo este arranque', () async {
    final store = freshStore();
    expect(
      store.register('maxi@nexora.dev', 'Secret1@2026', rememberMe: false),
      AuthResult.ok,
    );
    // En esta instancia hay sesión…
    expect(store.loggedIn, isTrue);

    // …pero otra instancia NO retoma sesión: pidió no quedar registrada.
    final reopened = freshStore();
    expect(reopened.loggedIn, isFalse);
    expect(reopened.account, isNotNull);

    // Con credenciales correctas entra, todavía sin persistir.
    expect(
      reopened.login('maxi@nexora.dev', 'Secret1@2026', rememberMe: false),
      AuthResult.ok,
    );
    final third = freshStore();
    expect(third.loggedIn, isFalse);
  });

  test('con "Recordarme" la sesión sobrevive al reinicio', () async {
    final store = freshStore();
    store.register('maxi@nexora.dev', 'Secret1@2026', rememberMe: true);
    final reopened = freshStore();
    expect(reopened.loggedIn, isTrue);
  });

  test('el registro guarda el perfil opcional (nombre, usuario, avatar)', () async {
    final store = freshStore();
    store.register(
      'maxi@nexora.dev',
      'Secret1@2026',
      name: 'Maxi',
      username: 'maxi_guard',
    );
    final reopened = freshStore();
    expect(reopened.account!.name, 'Maxi');
    expect(reopened.account!.username, 'maxi_guard');

    // Avatar opcional no rompe nada al persistir.
    expect(
      freshStore().register('avatar@nexora.dev', 'Secret2@2026'),
      AuthResult.emailTaken,
    );
  });

  test('updateProfile cambia el perfil sin tocar credenciales', () async {
    final store = freshStore();
    store.register('maxi@nexora.dev', 'Secret1@2026', username: 'antes');
    store.logout();

    final second = freshStore();
    expect(second.updateProfile(name: 'Nuevo', username: 'despues'), isTrue);

    final third = freshStore();
    expect(third.account!.name, 'Nuevo');
    expect(third.account!.username, 'despues');
    // La contraseña sigue validando contra el mismo hash.
    expect(third.login('maxi@nexora.dev', 'Secret1@2026'), AuthResult.ok);
  });

  test('recuperación offline responde honesto: nada se envía', () async {
    const service = LocalOfflineRecoveryService();
    expect(service.supported, isFalse);
    expect(
      await service.requestReset('maxi@nexora.dev'),
      PasswordRecoveryResult.notConfigured,
    );
  });
}
