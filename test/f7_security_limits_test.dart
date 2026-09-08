/// Tests FASE 7 spec — límites de seguridad de la autenticación:
/// bloqueo anti fuerza bruta del login, último acceso persistido y
/// ciclo de vida del código de recuperación (expiración, intentos y
/// invalidación por uso único).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';
import 'package:nexora_guard/core/password_recovery.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexora-f7-limits');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AuthStore freshStore({Duration? lockout}) {
    final store = AuthStore(
      dir,
      lockoutDuration: lockout ?? const Duration(seconds: 60),
    )..load();
    return store;
  }

  test('el login se bloquea tras el límite de intentos y libera al vencer', () async {
    final store = freshStore(lockout: const Duration(milliseconds: 60));
    store.register('cuenta@nexora.dev', 'Secret1@2026');
    // El atacante típico está sin sesión: se cierra para simularlo.
    store.logout();

    // 5 fallos consecutivos: cada uno devuelve el error genérico honesto.
    for (var i = 0; i < 5; i++) {
      expect(
        store.login('cuenta@nexora.dev', 'incorrecta'),
        AuthResult.wrongCredentials,
      );
    }
    // Mientras dura el bloqueo, hasta las credenciales correctas fallan y
    // la respuesta es distinta (bloqueado), sin revelar nada si no.
    expect(
      store.login('cuenta@nexora.dev', 'Secret1@2026'),
      AuthResult.locked,
    );
    expect(store.loggedIn, isFalse);

    // El bloqueo se persiste: otra instancia lo respeta.
    final reopened = AuthStore(dir)..load();
    expect(
      reopened.login('cuenta@nexora.dev', 'Secret1@2026'),
      AuthResult.locked,
    );

    // Al vencer el bloqueo, la cuenta vuelve a operar y el contador se limpia.
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(
      store.login('cuenta@nexora.dev', 'Secret1@2026'),
      AuthResult.ok,
    );
    expect(store.loggedIn, isTrue);
  });

  test('login registra y persiste la fecha del último acceso', () async {
    final store = freshStore();
    store.register('cuenta@nexora.dev', 'Secret1@2026');
    final atRegister = store.account!.lastAccessAtMillis;
    expect(atRegister, greaterThan(0));

    store.logout();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      store.login('cuenta@nexora.dev', 'Secret1@2026'),
      AuthResult.ok,
    );

    final atLogin = store.account!.lastAccessAtMillis;
    expect(atLogin, greaterThan(atRegister));

    final reopened = freshStore();
    expect(reopened.account!.lastAccessAtMillis, atLogin);
  });

  group('RecoveryChallenge', () {
    RecoveryChallenge challenge({int expiresInMillis = 60_000, int max = 3}) =>
        RecoveryChallenge(
          code: '123456',
          expiresAtMillis:
              DateTime.now().add(Duration(milliseconds: expiresInMillis)).millisecondsSinceEpoch,
          maxAttempts: max,
        );

    test('un código correcto es uso único: se invalida después de usarse', () {
      final c = challenge()..verify('111111'); // un fallo no lo invalida
      expect(c.verify('123456'), RecoveryCodeResult.ok);
      expect(c.verify('123456'), RecoveryCodeResult.exhausted);
    });

    test('agotar los intentos invalida el código y avisa', () {
      final c = challenge(max: 3);
      expect(c.verify('111111'), RecoveryCodeResult.wrong);
      expect(c.verify('222222'), RecoveryCodeResult.wrong);
      expect(c.verify('333333'), RecoveryCodeResult.wrong); // 3° fallo: agotado
      expect(c.verify('123456'), RecoveryCodeResult.exhausted);
    });

    test('un código vencido nunca se acepta', () {
      final c = challenge(expiresInMillis: -1);
      expect(c.verify('123456'), RecoveryCodeResult.expired);
      expect(c.verify('123456'), RecoveryCodeResult.expired);
    });
  });
}