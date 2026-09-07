/// Tests FASE 7 — seguridad de cuenta: cambio de contraseña (perfil),
/// restablecimiento por código (recuperación) y persistencia real del perfil.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexora-f7-auth');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AuthStore freshStore() {
    final store = AuthStore(dir)..load();
    return store;
  }

  test('changePassword exige la actual y rechaza la débil', () {
    final store = freshStore();
    store.register('cuenta@nexora.dev', 'Secret1@2026');

    expect(
      store.changePassword('mal-pasada', 'Nueva123Zeta'),
      PasswordChangeResult.wrongCurrent,
    );
    expect(
      store.changePassword('Secret1@2026', 'corta'),
      PasswordChangeResult.weakPassword,
    );
    expect(
      store.changePassword('Secret1@2026', 'Nueva123Zeta'),
      PasswordChangeResult.ok,
    );

    // La contraseña vieja ya no abre sesión; la nueva sí.
    store.logout();
    expect(store.login('cuenta@nexora.dev', 'Secret1@2026'), AuthResult.wrongCredentials);
    expect(store.login('cuenta@nexora.dev', 'Nueva123Zeta'), AuthResult.ok);
  });

  test('changePassword regenera el salt: el hash en disco cambia', () {
    final store = freshStore();
    store.register('cuenta@nexora.dev', 'Secret1@2026');
    final hashBefore = store.account!.hashHex;
    final saltBefore = store.account!.saltHex;

    store.changePassword('Secret1@2026', 'Nueva123Zeta');
    expect(store.account!.hashHex, isNot(hashBefore));
    expect(store.account!.saltHex, isNot(saltBefore));
  });

  test('resetPassword del recupero no exige la actual y persiste', () {
    final store = freshStore();
    store.register('cuenta@nexora.dev', 'Secret1@2026');
    store.logout();

    expect(store.resetPassword('Recuperada22b'), AuthResult.ok);
    expect(store.login('cuenta@nexora.dev', 'Secret1@2026'), AuthResult.wrongCredentials);
    expect(store.login('cuenta@nexora.dev', 'Recuperada22b'), AuthResult.ok);
  });

  test('resetPassword valida fuerza y ningún caso sin cuenta', () {
    final store = freshStore();
    expect(store.resetPassword('corta'), AuthResult.storage);

    store.register('cuenta@nexora.dev', 'Secret1@2026');
    expect(store.resetPassword('corta'), AuthResult.weakPassword);
  });

  test('updateProfile persiste nombre, usuario y avatar entre instancias', () {
    final store = freshStore();
    store.register('cuenta@nexora.dev', 'Secret1@2026', name: 'Antes', username: 'antes');

    expect(
      store.updateProfile(name: 'Después', username: 'despues_g', avatarBase64: 'AAAA'),
      isTrue,
    );

    final reopened = freshStore();
    expect(reopened.account!.name, 'Después');
    expect(reopened.account!.username, 'despues_g');
    expect(reopened.account!.avatarBase64, 'AAAA');
    // La sesión sigue abierta tras la edición.
    expect(reopened.loggedIn, isTrue);
  });
}