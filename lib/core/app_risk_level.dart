/// Clasificación de riesgo de 4 niveles para las apps — política ÚNICA y
/// testeable, separada de la UI (regla 40 del brief: nunca "malware" sin
/// evidencia).
///
/// Escala:
/// - [AppRiskLevel.safe]: sin señales relevantes.
/// - [AppRiskLevel.attention]: superficie sensible declarada/concedida o
///   origen no verificado, sin prueba de uso malicioso.
/// - [AppRiskLevel.suspicious]: elevado (sideload + señales fuertes) pero
///   sin capacidad activa que pruebe control remoto.
/// - [AppRiskLevel.critical]: capacidad CONCEDIDA y ACTIVA hoy
///   (accesibilidad / notificaciones / administrador del dispositivo) o
///   puntaje máximo del motor — el patrón real del spyware.
library;

import 'models.dart';

enum AppRiskLevel { safe, attention, suspicious, critical }

/// Señales que indican control remoto o distribución no oficial (fuertes,
/// pero no necesariamente activas).
const _strongFlags = {'overlay', 'installs-packages', 'device-admin'};

/// Clasifica una app usando SOLO evidencia observable. Principios:
/// 1. Una capacidad activa (accesibilidad/notif/device-admin) o un
///    veredicto crítico del motor ⇒ crítica.
/// 2. Advertencia del motor + sideload/señal fuerte ⇒ sospechosa.
/// 3. Advertencia sola, sideload solo, o superficie declarada ⇒ atención.
///    (Un permiso DECLARADO pero NO concedido es mucho más débil que uno
///    concedido: aplicaciones legítimas declaran de más por defecto.)
/// 4. Sin señales ⇒ segura.
AppRiskLevel classifyAppRisk(AppRisk app) {
  // La evidencia más fuerte que existe: concedido Y operando ahora mismo.
  if (app.activeCapabilities.isNotEmpty) return AppRiskLevel.critical;
  if (app.severity == Severity.critical) return AppRiskLevel.critical;

  final flags = app.specialFlags.toSet();
  final hasStrong = flags.intersection(_strongFlags).isNotEmpty;

  if (app.severity == Severity.warning && (app.sideloaded || hasStrong)) {
    return AppRiskLevel.suspicious;
  }
  if (app.severity == Severity.warning) return AppRiskLevel.attention;

  // severity == normal: pesan más los permisos CONCEDIDOS que los declarados.
  if (app.grantedPermissions.isNotEmpty) return AppRiskLevel.attention;
  if (app.sideloaded || hasStrong) return AppRiskLevel.attention;
  if (app.dangerousPermissions.length >= 3) return AppRiskLevel.attention;
  return AppRiskLevel.safe;
}