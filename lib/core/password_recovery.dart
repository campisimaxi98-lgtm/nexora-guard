/// Arquitectura de recuperación de contraseña — preparada, no simulada.
///
/// La app es cero-red por diseño: NO existe backend que envíe enlaces de
/// restablecimiento. Este archivo define el CONTRATO (interfaz) que usará
/// la pantalla de recupero, y la implementación local honesta que responde
/// "no disponible" cuando no hay servicio remoto. Cuando NEXORA GUARD tenga
/// backend (flavor `connected`), se inyecta una implementación real sin
/// tocar la UI.
library;

/// Resultado de una solicitud de restablecimiento.
enum PasswordRecoveryResult {
  /// Todo bien: el enlace se envió al correo (requiere backend).
  ok,

  /// Esta versión no tiene servicio de envío: nada se envió.
  notConfigured,
}

/// Resultado de verificar el código de un desafío de recuperación.
enum RecoveryCodeResult {
  /// El código es correcto y quedó consumido (uso único).
  ok,

  /// El texto no coincide con el código vigente (cuenta como intento).
  wrong,

  /// El código venció (por tiempo o por uso único ya consumido).
  expired,

  /// Se agotaron los intentos de este código: quedó invalidado.
  exhausted,
}

/// Desafío de código temporal para la recuperación de contraseña.
///
/// Cumple los requisitos del spec: el código es temporal (expira a los
/// [expiresAtMillis]), tiene fecha de expiración, se invalida al usarse
/// (uso único) y tiene un límite de intentos para frenar el abuso. En el
/// modo offline honesto el código se muestra en pantalla (la app no tiene
/// backend que lo envíe por correo), así que el desafío conserva el texto
/// en memoria ÚNICAMENTE para mostrarlo; la comparación de la verificación
/// se hace contra este mismo estado volátil de un solo widget, nunca se
/// persiste en disco.
class RecoveryChallenge {
  RecoveryChallenge({
    required this.code,
    required this.expiresAtMillis,
    this.maxAttempts = 5,
  });

  /// Código generado (6 dígitos), en memoria para mostrarlo sin red.
  final String code;

  /// Momento (epoch millis) desde el cual el código deja de ser válido.
  final int expiresAtMillis;

  /// Cantidad máxima de verificaciones incorrectas antes de invalidarlo.
  final int maxAttempts;

  int _attempts = 0;

  /// `true` una vez usado con éxito o invalidado por agotar intentos.
  bool _used = false;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _used || now >= expiresAtMillis;
  }

  /// Verifica [input] contra el código y aplica las reglas de seguridad.
  /// `ok` consume el código (uso único); los fallos agotan el desafío al
  /// llegar al límite de intentos.
  RecoveryCodeResult verify(String input) {
    if (_used) return RecoveryCodeResult.exhausted;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= expiresAtMillis) return RecoveryCodeResult.expired;
    if (input.trim() == code) {
      _used = true;
      return RecoveryCodeResult.ok;
    }
    _attempts++;
    if (_attempts >= maxAttempts) _used = true;
    return RecoveryCodeResult.wrong;
  }
}

/// Contrato de un proveedor de recuperación de contraseña.
abstract class PasswordRecoveryService {
  /// `true` si el servicio remoto existe y puede enviar enlaces.
  bool get supported;

  /// Solicita el restablecimiento para [email]. Nunca debe lanzar: devuelve
  /// un resultado que la UI traduce con honestidad.
  Future<PasswordRecoveryResult> requestReset(String email);
}

/// Implementación local (offline): nada se envía y lo dice claro.
class LocalOfflineRecoveryService implements PasswordRecoveryService {
  const LocalOfflineRecoveryService();

  @override
  bool get supported => false;

  @override
  Future<PasswordRecoveryResult> requestReset(String email) async =>
      PasswordRecoveryResult.notConfigured;
}