# Publicar NEXORA GUARD en las tiendas

Guía práctica para llevar la v1.0.0 a **Google Play** y **App Store**. Lo
automatizable ya está hecho y firmado; lo que queda son pasos de cuenta y
formularios que solo el dueño puede completar.

---

## 1. Lo que YA está resuelto en este repo

| Requisito | Estado |
|---|---|
| Firma release propia | `C:\Users\Usuario\dev\keys\nexora-upload.jks` (alias `nexora-upload`, vigencia 10.000 días). Gradle la usa si existen variables de entorno (CI) **o** `android/key.properties` (local); si no hay nada, cae a debug para poder compilar igual. |
| App Bundle de Play | `build/app/outputs/bundle/release/app-release.aab` — **firmado con el keystore nuevo** (`jarsigner -verify`: "jar verified"). |
| Ícono 512×512 | `store/app-icon-512.png` |
| Feature graphic 1024×500 | `store/feature-graphic-1024x500.png` |
| Política de privacidad pública | <https://campisimaxi98-lgtm.github.io/nexora-guard/privacidad.html> |
| Versión | `1.0.0+12` (`pubspec.yaml` y `Meta.version`) |
| Bundle / package ID | `com.nexora.guard` |
| SDK | minSdk 24 · target/compile 36 (cumple el requisito actual de Play) |
| Permisos | Ninguno peligroso; **sin INTERNET** en release (lo verifica `scripts/check-no-internet.sh`). Respuesta estrella para el formulario de seguridad de datos. |

### ⚠️ RESPALDA EL KEYSTORE HOY

Si perdés `nexora-upload.jks` perdés la identidad de la app en Play.

- Copia del archivo: dejá una en un pendrive y otra en tu nube personal.
- Contraseña y alias: están en `android/key.properties` (archivo **gitignored**,
  nunca se sube al repo) y te las di por chat. Guárdalas en un gestor de
  contraseñas.
- Con "Play App Signing" activado (viene por defecto), Google conserva la clave
  de firma final y la de subida puede resetearse desde Play Console si se
  pierde — pero solo si completás el alta de la app primero.

Para regenerar los artefactos gráficos tras cambiar la marca:

```powershell
flutter test --update-goldens test/store_assets_test.dart
python scripts/make_store_assets.py
```

---

## 2. Google Play Store

### 2.1 Cuenta (una sola vez)

1. Crear cuenta de **Google Play Developer**: <https://play.google.com/console>
   (pago único ~USD 25).
2. Completar identificación y aceptar acuerdos.

### 2.2 Crear la app

Play Console → *Crear app*:

- Nombre: `NEXORA GUARD`
- Idioma: Español (o el que prefieras como principal)
- Tipo: Aplicación · Gratis
- Declaraciones: aceptar ambos (programas y exportación a EE. UU.; la app usa
  criptografía estándar SHA-256 incluida en el SO → exención general).

### 2.3 Ficha de tienda (texto listo para copiar)

- **Título (30):** `NEXORA GUARD: Diagnóstico local`
- **Descripción corta (80):**
  > Sensor forense que vigila memoria, batería, red y apps. Sin internet.
- **Descripción completa:** partir de la filosofía del README (diagnóstico
  primero, intervención después; evidencia local con cadena SHA-256;
  explicación honesta de cada hallazgo; cinco idiomas).

### 2.4 Gráficos

- Ícono: `store/app-icon-512.png`
- Imagen destacada: `store/feature-graphic-1024x500.png`
- Capturas: mínimo **2**. Tomalas reales instalando
  `app-arm64-v8a-release.apk` en tu teléfono (Android moderno) y capturando:
  1. Resumen (veredicto + panel rápido + dona)
  2. Historial (gráfico interactivo con burbuja)
  3. Bienvenida (escudo + formularios) — recomendada
  Recomendación: teléfono físico o emulador con `flutter run --release`.

### 2.5 Formulario de seguridad de datos ("Recolección de datos")

Respuestas correctas para esta app:

- ¿Recopila o comparte datos personales? → **No** (sin internet, sin
  telemetría, todo en sandbox local; la cuenta es local).
- Cifrado en tránsito → No aplica (no hay transmisión).
- Borrado de datos → Sí, el usuario puede borrar evidencia y desinstalar.

### 2.6 Clasificación de contenido

Cuestionario estándar: sin violencia, sin apuestas, sin compras dentro de la
app, sin interacción social → resultado esperado **Todos** / "E".

### 2.7 Subir la versión

Producción → crear release → subir `app-release.aab` → notas de versión
(usar el bloque `[1.0.0]` del CHANGELOG) → revisión y publicación.

> La primera revisión suele tardar de 1 a 7 días.

---

## 3. Apple App Store (iOS)

### Requisitos duros (no negociables)

- **Mac con Xcode** (el `.ipa` no se puede compilar desde Windows).
- **Apple Developer Program**: USD 99/año — <https://developer.apple.com>

### Pasos una vez tengas el Mac

1. `flutter build ipa --release` (usa el mismo código; el proyecto ya incluye
   la carpeta `ios/`).
2. Subir con Transporter o Xcode Organizer a App Store Connect.
3. Crear la app en App Store Connect (bundle ID `com.nexora.guard`,
   SKU `nexora-guard`).
4. Ficha: mismos textos e imágenes de Play (generar capturas de iOS desde el
   simulador: Resumen e Historial funcionan; Apps no lista en iOS por diseño
   del SO — la app lo explica en pantalla).
5. Privacidad: "No se recopilan datos".
6. En `ios/Runner/Info.plist` ya deben estar los textos de uso de Bluetooth
   (Cercanía); verificarlos antes de archivar.

### Estado honesto

El código es multiplataforma y compila para iOS, pero **hoy no hay forma de
producir el binario iOS desde esta máquina** — queda bloqueado por hardware,
no por software.

---

## 4. Checklist exprés

```text
[ ] Respaldé nexora-upload.jks + contraseña (pendrive/nube/gestor)
[ ] Cuenta Play Developer creada
[ ] Subí app-release.aab a producción
[ ] Ícono + feature graphic + 2 capturas cargadas
[ ] Seguridad de datos: "No recopila"
[ ] Política de privacidad: URL de GitHub Pages pegada
[ ] Clasificación completada
[ ] Publicado
[ ] (iOS) Mac + cuenta Apple Developer cuando esté disponible
```
