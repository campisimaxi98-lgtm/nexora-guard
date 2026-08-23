# Flavor `connected` — chat en línea con el backend NEXORA GUARD

## Por qué existe esto separado

El producto tiene una garantía central: **cero red saliente**, verificada por
el propio sistema operativo (sin `android.permission.INTERNET` en el
manifiesto de release, Android bloquea cualquier socket). Eso es lo que
distribuye por defecto el flavor `offline`.

El chatbot "Nexora" puede opcionalmente hablar con un backend real
(NEXORA GUARD, el proyecto Node.js con Claude — ver ese repo) para dar
respuestas mejores que las reglas locales. Eso requiere el permiso
`INTERNET`, así que **no podía sumarse al mismo binario** sin romper la
garantía de todo el mundo, aunque nadie activara el chat. Por eso es un
flavor aparte, con su propio manifiesto.

## Los dos flavors

| Flavor | Permiso INTERNET | Chat "Nexora" | Uso previsto |
|---|---|---|---|
| `offline` (default) | No | Solo local, respuestas predefinidas | Distribución pública normal |
| `connected` | Sí | Local + en línea (opt-in con consentimiento en la app) | Builds propios, para quien aloja su propio backend |

## Comandos de build

```bash
# El de siempre — sin cambios en el comportamiento público:
flutter build apk --flavor offline --release
bash scripts/check-no-internet.sh

# La variante conectada:
flutter build apk --flavor connected --release --dart-define=NEXORA_FLAVOR=connected
bash scripts/check-connected-has-internet.sh
```

**Importante:** el flag de Gradle (`--flavor connected`) y el flag de Dart
(`--dart-define=NEXORA_FLAVOR=connected`) son dos cosas separadas — el
primero controla el manifiesto/permisos nativos, el segundo controla qué ve
la UI de Flutter (`lib/core/app_flavor.dart`). **Hay que pasar los dos
juntos** para el flavor conectado, o vas a tener el permiso sin la UI, o la
UI sin el permiso.

## Qué cambia para quien usa la variante `connected`

1. En la pantalla "Nexora" (el chat), aparece un ícono de nube en la barra
   superior.
2. Al tocarlo, pide la URL del backend propio (`https://tu-dominio.com`) y
   un checkbox de consentimiento explícito — sin marcar ese checkbox, el
   chat sigue siendo local aunque el flavor lo permita.
3. Solo con URL configurada + checkbox marcado, los mensajes salen del
   teléfono. Se muestra un aviso fijo arriba del chat mientras esto está
   activo.
4. El resto de la app (análisis de dispositivo, apps, red, etc.) sigue
   siendo 100% local en ambos flavors — esto solo afecta al chat.

## Una asimetría importante: iOS

Todo lo de arriba (el permiso `INTERNET` bloqueado a nivel de sistema
operativo) es **específico de Android**. iOS no tiene un permiso declarado
equivalente para "esta app puede hacer HTTP(S)" — cualquier app puede hacer
requests de red en iOS salvo que uses excepciones de ATS para HTTP sin
cifrar. Eso significa que en iOS la garantía de "cero red" del flavor
`offline` depende **enteramente** del flag de compilación
(`NEXORA_FLAVOR`), no de algo que el sistema operativo bloquee por sí solo.

En la práctica sigue siendo sólido: sin pasar
`--dart-define=NEXORA_FLAVOR=connected` explícitamente en el build, el
código de `NexoraChatClient` nunca se ejecuta en ninguna plataforma. Pero
vale la distinción para no repetir en iOS la misma afirmación ("el SO lo
impide") que sí es literalmente cierta en Android.

## Publicación

Si vas a publicar ambas variantes (por ejemplo, `offline` en la tienda
principal y `connected` para distribución directa a quien la pida), usá
`applicationIdSuffix` en el flavor `connected` dentro de
`android/app/build.gradle.kts` para que puedan instalarse simultáneamente en
el mismo dispositivo sin pisarse. Hoy comparten `applicationId` a propósito
(para minimizar el diff de esta primera versión) — separalos si vas a
distribuir las dos.
