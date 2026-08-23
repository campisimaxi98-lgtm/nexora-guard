/// Cuentas locales de NEXORA GUARD — Dart puro (`dart:io` + JSON).
///
/// La app es cero-red por diseño: no existe backend ni identidad en la nube.
/// La cuenta vive SOLO en este teléfono y funciona como puerta de entrada
/// local (privacidad frente a quien toma el teléfono prestado), nunca como
/// cuenta sincronizable. La contraseña jamás se guarda: se guarda SHA-256
/// estirada con salt aleatorio de 128 bits (misma primitiva que sella la
/// cadena del historial, verificada contra vectores FIPS en `test/`).
///
/// Toda la API es SÍNCRONA a propósito: opera sobre un único JSON minúsculo
/// del sandbox y se invoca en el arranque (antes del primer frame útil) y en
/// respuesta a un tap. El costo es despreciable y elimina la carrera
/// clásica "gate que decide con estado a medias".
///
/// Honestidad sobre el alcance: esto NO resiste a un atacante con root ni
/// sustituye cifrado en reposo — es una cerradura razonable para uso
/// cotidiano, coherente con "diagnóstico primero".
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'sha256.dart';

/// Resultado de una operación de autenticación. Los ids son neutrales al
/// idioma: la UI los traduce vía [AppStrings].
enum AuthResult {
  ok,
  invalidEmail,
  weakPassword,
  emailTaken,
  wrongCredentials,
  storage,
}

/// Cuenta registrada en este dispositivo.
class AuthAccount {
  const AuthAccount({
    required this.email,
    required this.saltHex,
    required this.hashHex,
    required this.createdAtMillis,
  });

  factory AuthAccount.fromMap(Map<String, dynamic> map) => AuthAccount(
    email: map['email'] as String? ?? '',
    saltHex: map['saltHex'] as String? ?? '',
    hashHex: map['hashHex'] as String? ?? '',
    createdAtMillis: (map['createdAtMillis'] as num?)?.toInt() ?? 0,
  );

  final String email;
  final String saltHex;
  final String hashHex;
  final int createdAtMillis;

  Map<String, dynamic> toMap() => {
    'email': email,
    'saltHex': saltHex,
    'hashHex': hashHex,
    'createdAtMillis': createdAtMillis,
  };
}

class AuthStore {
  AuthStore(this.directory);

  /// Carpeta de datos donde vive `nexora-auth.json`.
  final Directory directory;
  static const _fileName = 'nexora-auth.json';

  /// Estiramiento de clave: iteraciones de SHA-256. Es deliberadamente
  /// modesto: corre en teléfonos viejos y la amenaza objetivo es el uso
  /// casual, no un ataque offline dedicado.
  static const _iterations = 4096;

  AuthAccount? _account;
  bool _loggedIn = false;

  /// Cuenta registrada, si existe. Solo válida después de [load].
  AuthAccount? get account => _account;

  /// Hay una sesión abierta (tras registrar o iniciar sesión).
  bool get loggedIn => _loggedIn && _account != null;

  /// Carga el estado desde disco. Un archivo corrupto o ausente degrada a
  /// "sin cuenta": la pantalla de bienvenida ofrece crear una nueva.
  void load() {
    _account = null;
    _loggedIn = false;
    try {
      final file = File('${directory.path}/$_fileName');
      if (!file.existsSync()) return;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return;
      final raw = decoded['account'];
      if (raw is! Map<String, dynamic>) return;
      _account = AuthAccount.fromMap(raw);
      _loggedIn = decoded['loggedIn'] == true;
    } on FileSystemException {
      // Sin acceso al archivo se opera sin cuenta (igual que la config).
    } on FormatException {
      // JSON corrupto: se descarta y arranca limpio.
    }
  }

  /// Registra la única cuenta permitida por dispositivo y abre sesión.
  AuthResult register(String email, String password) {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }
    if (password.length < 6) return AuthResult.weakPassword;
    if (_account != null) return AuthResult.emailTaken;

    final random = Random.secure();
    final saltHex = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final account = AuthAccount(
      email: normalized,
      saltHex: saltHex,
      hashHex: _stretch(password, saltHex),
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    return _persist(account, loggedIn: true)
        ? AuthResult.ok
        : AuthResult.storage;
  }

  /// Verifica credenciales contra la cuenta existente y abre sesión.
  AuthResult login(String email, String password) {
    final account = _account;
    if (account == null || email.trim().toLowerCase() != account.email) {
      return AuthResult.wrongCredentials;
    }
    if (_stretch(password, account.saltHex) != account.hashHex) {
      return AuthResult.wrongCredentials;
    }
    return _persist(account, loggedIn: true)
        ? AuthResult.ok
        : AuthResult.storage;
  }

  /// Cierra la sesión conservando la cuenta (volverá a pedir credenciales).
  void logout() {
    _persist(_account, loggedIn: false);
  }

  /// Elimina también la cuenta (borrado total de evidencia).
  void wipe() {
    _account = null;
    _loggedIn = false;
    try {
      final file = File('${directory.path}/$_fileName');
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Nada que hacer: queda como si no hubiera cuenta.
    }
  }

  /// Estira la contraseña: SHA-256 encadenada con salt prefijado. El hash
  /// intermedio se re-procesa completo, así que cada iteración cuesta lo
  /// mismo y ninguna tabla precalculada sirve entre instalaciones.
  String _stretch(String password, String saltHex) {
    var digest = sha256Hex('$saltHex:$password');
    for (var i = 1; i < _iterations; i++) {
      digest = sha256Hex(digest);
    }
    return digest;
  }

  bool _persist(AuthAccount? account, {required bool loggedIn}) {
    try {
      final file = File('${directory.path}/$_fileName');
      if (account == null) {
        if (file.existsSync()) file.deleteSync();
      } else {
        file.writeAsStringSync(
          jsonEncode({'account': account.toMap(), 'loggedIn': loggedIn}),
          flush: true,
        );
      }
      _account = account ?? _account;
      _loggedIn = loggedIn && account != null;
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
