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
import 'dart:typed_data';

import 'sha256.dart';

/// Codifica bytes de imagen (PNG) como Base64 sin prefijo — mismo formato
/// que entrega el colector nativo para los íconos de apps. Vive en el
/// núcleo para que no haya codificadores duplicados en la UI.
String avatarToBase64(Uint8List bytes) => base64Encode(bytes);

/// Decodifica el Base64 sin prefijo de la UI de vuelta a bytes (perfil).
/// Nunca debe lanzar: devuelve `null` ante entrada no decodificable.
Uint8List? avatarFromBase64(String b64) {
  if (b64.isEmpty) return null;
  try {
    return base64Decode(b64.replaceAll('\n', '').replaceAll('\r', ''));
  } on FormatException {
    return null;
  }
}

/// Resultado de una operación de autenticación. Los ids son neutrales al
/// idioma: la UI los traduce vía [AppStrings].
enum AuthResult {
  ok,
  invalidEmail,
  weakPassword,
  emailTaken,
  wrongCredentials,

  /// Demasiados intentos fallidos seguidos: el login quedó bloqueado un rato.
  locked,
  storage,
}

/// Resultado del cambio de contraseña con verificación de la actual.
enum PasswordChangeResult {
  ok,
  weakPassword,
  wrongCurrent,
  storage,
}

/// Cumplimiento de las reglas de contraseña fuerte (FASE 8): 8+ caracteres,
/// una mayúscula, una minúscula y un número. La UI pinta su checklist a
/// partir de esta misma estructura — una sola fuente de verdad.
class PasswordShape {
  const PasswordShape({
    required this.length,
    required this.upper,
    required this.lower,
    required this.digit,
  });

  final bool length;
  final bool upper;
  final bool lower;
  final bool digit;

  /// Todos los requisitos cumplidos → contraseña aceptable.
  bool get isStrong => length && upper && lower && digit;
}

/// Regla compartida de contraseña fuerte: el almacén y la pantalla de cuenta
/// la usan igual, así no pueden discrepar.
PasswordShape passwordShape(String password) => PasswordShape(
  length: password.length >= 8,
  upper: password.contains(RegExp(r'[A-Z]')),
  lower: password.contains(RegExp(r'[a-z]')),
  digit: password.contains(RegExp(r'[0-9]')),
);

/// Cuenta registrada en este dispositivo.
class AuthAccount {
  const AuthAccount({
    required this.email,
    required this.saltHex,
    required this.hashHex,
    required this.createdAtMillis,
    this.lastAccessAtMillis = 0,
    this.name = '',
    this.username = '',
    this.avatarBase64 = '',
  });

  factory AuthAccount.fromMap(Map<String, dynamic> map) => AuthAccount(
    email: map['email'] as String? ?? '',
    saltHex: map['saltHex'] as String? ?? '',
    hashHex: map['hashHex'] as String? ?? '',
    createdAtMillis: (map['createdAtMillis'] as num?)?.toInt() ?? 0,
    lastAccessAtMillis: (map['lastAccessAtMillis'] as num?)?.toInt() ?? 0,
    name: map['name'] as String? ?? '',
    username: map['username'] as String? ?? '',
    avatarBase64: map['avatarBase64'] as String? ?? '',
  );

  final String email;
  final String saltHex;
  final String hashHex;
  final int createdAtMillis;

  /// Momento del último acceso con credenciales válidas (0 = nunca).
  final int lastAccessAtMillis;

  /// Perfil opcional del registro: nombre visible y usuario corto.
  final String name;
  final String username;

  /// Avatar del perfil como PNG en Base64 (sin prefijo data:). Vacío = sin foto.
  final String avatarBase64;

  Map<String, dynamic> toMap() => {
    'email': email,
    'saltHex': saltHex,
    'hashHex': hashHex,
    'createdAtMillis': createdAtMillis,
    'lastAccessAtMillis': lastAccessAtMillis,
    'name': name,
    'username': username,
    if (avatarBase64.isNotEmpty) 'avatarBase64': avatarBase64,
  };

  AuthAccount copyWith({
    String? name,
    String? username,
    String? avatarBase64,
  }) => AuthAccount(
    email: email,
    saltHex: saltHex,
    hashHex: hashHex,
    createdAtMillis: createdAtMillis,
    lastAccessAtMillis: lastAccessAtMillis,
    name: name ?? this.name,
    username: username ?? this.username,
    avatarBase64: avatarBase64 ?? this.avatarBase64,
  );
}

class AuthStore {
  AuthStore(
    this.directory, {
    this.maxFailedAttempts = 5,
    this.lockoutDuration = const Duration(seconds: 60),
  });

  /// Carpeta de datos donde vive `nexora-auth.json`.
  final Directory directory;
  static const _fileName = 'nexora-auth.json';

  /// Cantidad de fallos de login consecutivos que disparan el bloqueo.
  final int maxFailedAttempts;

  /// Duración del bloqueo tras alcanzar el límite (anti fuerza bruta).
  final Duration lockoutDuration;

  /// Estiramiento de clave: iteraciones de SHA-256. Es deliberadamente
  /// modesto: corre en teléfonos viejos y la amenaza objetivo es el uso
  /// casual, no un ataque offline dedicado.
  static const _iterations = 4096;

  AuthAccount? _account;
  bool _loggedIn = false;

  /// Si la sesión actual se persiste entre arranques ("Recordarme"). Sin
  /// `load()` no tiene sentido; se deduce del archivo (sesión persistida).
  bool _rememberMe = true;

  /// Fallos de login consecutivos (se resetean al acertar o tras el bloqueo).
  int _failedAttempts = 0;

  /// Epoch millis hasta el cual el login queda bloqueado (0 = no bloqueado).
  int _lockedUntilMillis = 0;

  /// Cuenta registrada, si existe. Solo válida después de [load].
  AuthAccount? get account => _account;

  /// Hay una sesión abierta (tras registrar o iniciar sesión).
  bool get loggedIn => _loggedIn && _account != null;

  /// Carga el estado desde disco. Un archivo corrupto o ausente degrada a
  /// "sin cuenta": la pantalla de bienvenida ofrece crear una nueva.
  void load() {
    _account = null;
    _loggedIn = false;
    _rememberMe = false;
    _failedAttempts = 0;
    _lockedUntilMillis = 0;
    try {
      final file = File('${directory.path}/$_fileName');
      if (!file.existsSync()) return;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return;
      final raw = decoded['account'];
      if (raw is! Map<String, dynamic>) return;
      _account = AuthAccount.fromMap(raw);
      _loggedIn = decoded['loggedIn'] == true;
      _rememberMe = _loggedIn;
      final lock = decoded['lockout'];
      if (lock is Map<String, dynamic>) {
        _failedAttempts = (lock['failed'] as num?)?.toInt() ?? 0;
        _lockedUntilMillis = (lock['until'] as num?)?.toInt() ?? 0;
      }
    } on FileSystemException {
      // Sin acceso al archivo se opera sin cuenta (igual que la config).
    } on FormatException {
      // JSON corrupto: se descarta y arranca limpio.
    }
  }

  /// Registra la única cuenta permitida por dispositivo y abre sesión.
  /// Con `rememberMe` en false la sesión NO se persiste: dura solo este
  /// arranque y el próximo abrir pedirá credenciales de nuevo (privacidad
  /// de quien comparte el teléfono).
  AuthResult register(
    String email,
    String password, {
    String name = '',
    String username = '',
    String avatarBase64 = '',
    bool rememberMe = true,
  }) {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return AuthResult.invalidEmail;
    }
    if (!passwordShape(password).isStrong) return AuthResult.weakPassword;
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
      lastAccessAtMillis: DateTime.now().millisecondsSinceEpoch,
      name: name.trim(),
      username: username.trim(),
      avatarBase64: avatarBase64,
    );
    return _persist(account, loggedIn: true, rememberMe: rememberMe)
        ? AuthResult.ok
        : AuthResult.storage;
  }

  /// Verifica credenciales contra la cuenta existente y abre sesión.
  /// `rememberMe` controla si la sesión sobrevive al cierre de la app.
  ///
  /// Anti fuerza bruta: tras [maxFailedAttempts] fallos consecutivos el
  /// login queda bloqueado [lockoutDuration] (se persiste, sobrevive al
  /// reinicio). El contador se resetea al acertar o cuando expira el
  /// bloqueo. El error es genérico: nunca revela si el correo existe.
  AuthResult login(
    String email,
    String password, {
    bool rememberMe = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < _lockedUntilMillis) return AuthResult.locked;
    // Bloqueo vencido: abre una ventana nueva de intentos.
    if (_lockedUntilMillis > 0) {
      _failedAttempts = 0;
      _lockedUntilMillis = 0;
    }

    final account = _account;
    if (account == null || email.trim().toLowerCase() != account.email) {
      return _registerFailedAttempt(now);
    }
    if (_stretch(password, account.saltHex) != account.hashHex) {
      return _registerFailedAttempt(now);
    }

    // Credenciales correctas: se registra el último acceso y se libera el
    // contador de fallos (el archivo se reescribe con todo al día).
    _failedAttempts = 0;
    _lockedUntilMillis = 0;
    final updated = AuthAccount(
      email: account.email,
      saltHex: account.saltHex,
      hashHex: account.hashHex,
      createdAtMillis: account.createdAtMillis,
      lastAccessAtMillis: now,
      name: account.name,
      username: account.username,
      avatarBase64: account.avatarBase64,
    );
    return _persist(
      updated,
      loggedIn: true,
      rememberMe: rememberMe,
    )
        ? AuthResult.ok
        : AuthResult.storage;
  }

  /// Cuenta un fallo de login y bloquea si se llega al límite. Devuelve el
  /// resultado honesto de esta operación (bloqueado o credenciales malas).
  AuthResult _registerFailedAttempt(int now) {
    _failedAttempts++;
    if (_failedAttempts >= maxFailedAttempts) {
      _failedAttempts = 0;
      _lockedUntilMillis = now + lockoutDuration.inMilliseconds;
    }
    _persistLockout();
    return AuthResult.wrongCredentials;
  }

  /// Re-escribe el estado a disco con el contador de intentos al día. El
  /// bloqueo sobrevive al reinicio; la sesión en curso no cambia.
  void _persistLockout() {
    try {
      final file = File('${directory.path}/$_fileName');
      if (_account == null || !file.existsSync()) return;
      file.writeAsStringSync(
        jsonEncode({
          'account': _account!.toMap(),
          'loggedIn': _loggedIn && _rememberMe,
          'lockout': {
            'failed': _failedAttempts,
            'until': _lockedUntilMillis,
          },
        }),
        flush: true,
      );
    } on FileSystemException {
      // Si el disco falla, el contador queda solo en memoria: se reintenta
      // en el próximo intento; nada crítico se pierde.
    }
  }

  /// Cambia la contraseña verificando la ACTUAL (se usa desde el perfil).
  /// Regenera el salt: ningún resto de la contraseña vieja queda en disco.
  PasswordChangeResult changePassword(
    String currentPassword,
    String newPassword,
  ) {
    final account = _account;
    if (account == null) return PasswordChangeResult.storage;
    if (_stretch(currentPassword, account.saltHex) != account.hashHex) {
      return PasswordChangeResult.wrongCurrent;
    }
    if (!passwordShape(newPassword.trim()).isStrong) {
      return PasswordChangeResult.weakPassword;
    }
    final (newSalt, newHash) = _newSaltAndHash(newPassword.trim());
    final updated = AuthAccount(
      email: account.email,
      saltHex: newSalt,
      hashHex: newHash,
      createdAtMillis: account.createdAtMillis,
      lastAccessAtMillis: account.lastAccessAtMillis,
      name: account.name,
      username: account.username,
      avatarBase64: account.avatarBase64,
    );
    return _persist(updated, loggedIn: _loggedIn, rememberMe: _rememberMe)
        ? PasswordChangeResult.ok
        : PasswordChangeResult.storage;
  }

  /// Restablece la contraseña del flujo de recuperación (verificado por el
  /// código local, sin exigir la contraseña actual). Regenera el salt.
  AuthResult resetPassword(String newPassword) {
    final account = _account;
    if (account == null) return AuthResult.storage;
    if (!passwordShape(newPassword.trim()).isStrong) {
      return AuthResult.weakPassword;
    }
    final (newSalt, newHash) = _newSaltAndHash(newPassword.trim());
    final updated = AuthAccount(
      email: account.email,
      saltHex: newSalt,
      hashHex: newHash,
      createdAtMillis: account.createdAtMillis,
      lastAccessAtMillis: account.lastAccessAtMillis,
      name: account.name,
      username: account.username,
      avatarBase64: account.avatarBase64,
    );
    return _persist(updated, loggedIn: _loggedIn, rememberMe: _rememberMe)
        ? AuthResult.ok
        : AuthResult.storage;
  }

  (String, String) _newSaltAndHash(String password) {
    final random = Random.secure();
    final saltHex = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return (saltHex, _stretch(password, saltHex));
  }

  /// Actualiza el perfil (nombre, usuario, avatar) sin tocar credenciales.
  /// Mantiene la sesión abierta. Devuelve `false` si el disco falló.
  bool updateProfile({
    String? name,
    String? username,
    String? avatarBase64,
  }) {
    final account = _account;
    if (account == null) return false;
    final updated = account.copyWith(
      name: name,
      username: username,
      avatarBase64: avatarBase64,
    );
    return _persist(
      updated,
      loggedIn: _loggedIn,
      rememberMe: _rememberMe,
    );
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

  bool _persist(
    AuthAccount? account, {
    required bool loggedIn,
    bool rememberMe = true,
  }) {
    try {
      final file = File('${directory.path}/$_fileName');
      if (account == null) {
        if (file.existsSync()) file.deleteSync();
      } else {
        // "Recordarme": el flag de sesión se escribe SOLO si el usuario lo
        // pidió; en memoria la sesión queda igual para este arranque.
        final persistedLoggedIn = loggedIn && rememberMe;
        file.writeAsStringSync(
          jsonEncode({
            'account': account.toMap(),
            'loggedIn': persistedLoggedIn,
            'lockout': {
              'failed': _failedAttempts,
              'until': _lockedUntilMillis,
            },
          }),
          flush: true,
        );
      }
      _account = account ?? _account;
      _loggedIn = loggedIn && account != null;
      _rememberMe = loggedIn && rememberMe;
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
