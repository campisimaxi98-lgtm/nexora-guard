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