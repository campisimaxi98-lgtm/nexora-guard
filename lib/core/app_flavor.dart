/// Distingue en tiempo de compilación entre los dos flavors del producto:
///
/// - `offline` (por defecto): el que se publica normalmente. El manifiesto
///   de release NO declara `android.permission.INTERNET` — sin ese
///   permiso, Android bloquea cualquier socket saliente a nivel de
///   sistema operativo. `check-no-internet.sh` verifica esto en CI.
/// - `connected`: variante separada, con su propio manifiesto
///   (`android/app/src/connected/AndroidManifest.xml`) que sí declara
///   `INTERNET`, para habilitar el chat real con el backend NEXORA GUARD.
///
/// Se define con `--dart-define=NEXORA_FLAVOR=connected` al compilar (ver
/// `docs/connected-flavor.md`). Sin ese flag, el valor por defecto es
/// `offline`, así que un build normal (`flutter build apk --release`)
/// sigue siendo exactamente el binario "cero red" de siempre.
library;

class AppFlavor {
  const AppFlavor._();

  static const String name = String.fromEnvironment(
    'NEXORA_FLAVOR',
    defaultValue: 'offline',
  );

  static bool get isConnected => name == 'connected';
}
