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
      expect(store.register('Maxi@Ejemplo.com', 'secreta1'), AuthResult.ok);
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
      store.register('no-es-un-correo', 'secreta1'),
      AuthResult.invalidEmail,
    );
    expect(store.register('a@b.co', 'corta'), AuthResult.weakPassword);
    expect(store.account, isNull);
  });

  test('una sola cuenta por teléfono', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'secreta1');
    expect(store.register('dos@nexora.dev', 'secreta2'), AuthResult.emailTaken);
    // La original sigue intacta.
    final other = freshStore();
    expect(other.account!.email, 'uno@nexora.dev');
  });

  test('login valida credenciales contra el hash estirado', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'secreta1');
    store.logout();

    final second = freshStore();
    expect(
      second.login('otro@nexora.dev', 'secreta1'),
      AuthResult.wrongCredentials,
    );
    expect(
      second.login('uno@nexora.dev', 'incorrecta'),
      AuthResult.wrongCredentials,
    );
    expect(second.loggedIn, isFalse);
    expect(second.login('UNO@Nexora.dev ', 'secreta1'), AuthResult.ok);
    expect(second.loggedIn, isTrue);
  });

  test('logout cierra la sesión y conserva la cuenta', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'secreta1');

    final other = freshStore();
    other.logout();

    final reopened = freshStore();
    expect(reopened.loggedIn, isFalse);
    expect(reopened.account, isNotNull);
  });

  test('wipe deja el estado como recién instalado', () async {
    final store = freshStore();
    store.register('uno@nexora.dev', 'secreta1');
    store.wipe();

    final reopened = freshStore();
    expect(reopened.account, isNull);
    expect(reopened.loggedIn, isFalse);
    // Y se puede registrar de nuevo desde cero.
    expect(reopened.register('nuevo@nexora.dev', 'secreta3'), AuthResult.ok);
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
}
