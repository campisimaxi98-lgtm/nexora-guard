/// Pantallas de la app — punto de entrada único.
///
/// Hasta v0.7.0 esto era un solo archivo de ~1.900 líneas: añadir una
/// pestaña obligaba a navegar un monolito. Desde v0.8.0 cada pestaña vive en
/// su propio archivo bajo `screens/` y este barril los reexporta, así que
/// `import 'ui/screens.dart'` sigue funcionando igual para `main.dart` y los
/// tests — el cambio es estructural, no de comportamiento.
///
/// Las piezas de UI compartidas (formateadores, semáforo, tarjeta de
/// hallazgo) viven en `ui/widgets.dart`.
///
/// Sin lógica de negocio en ninguno: eso vive en `lib/core/`.
library;

export 'screens/about.dart';
export 'screens/apps.dart';
export 'screens/auth.dart';
export 'screens/device.dart';
export 'screens/history.dart';
export 'screens/nearby.dart';
export 'screens/network.dart';
export 'screens/nexora_cover.dart';
export 'screens/nexora_dashboard.dart';
export 'screens/nexora_play.dart';
export 'screens/nexora_apps.dart';
export 'screens/nexora_signals.dart';
export 'screens/nexora_shell.dart';
export 'screens/nexora_charts.dart';
export 'screens/nexora_alerts.dart';
export 'screens/nexora_protection.dart';
export 'screens/nexora_profile.dart';
export 'screens/nexora_premium.dart';
export 'screens/nexora_bot.dart';
export 'screens/onboarding.dart';
export 'screens/settings.dart';
export 'screens/storage.dart';
export 'screens/summary.dart';
export 'widgets.dart';
