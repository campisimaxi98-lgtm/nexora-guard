# ROADMAP ECOSISTEMA — NEXORA GUARD (evolución siguiente a la v1.0.1)

> Este documento planifica la EVOLUCIÓN pedida en el brief de 40 puntos.
> El estado de la v1.0.1 (FASES 1–11 del rediseño) NO se toca ni se rompe:
> cada fase de acá compila y deja la suite de tests verde antes de pasar
> a la siguiente. Base de partida: 210 tests / `flutter analyze` 1 info.

## Reglas de la casa (heredadas e innegociables)

- Cero internet en el flavor `offline`; cero dependencias externas nuevas.
- **Nunca mentir**: no se simula recuperación de contraseña, ni pagos, ni
  datos que la plataforma no entrega. Todo lo que se muestra es real o dice
  explícitamente que no está disponible.
- Todo texto nuevo es i18n ×5 (es/en/pt/it/fr) vía `AppStrings`.
- Severidad siempre con texto + color. Nada de indicadores solo visuales.
- No sacrificar funcionalidad, rendimiento, seguridad ni simplicidad por estética.
- Metodología: analizar → planificar → implementar → compilar → probar → corregir.
- 80% visual / 20% texto en cada pantalla nueva.
- La v1.0.1 queda publicada (tag `v1.0.1`): la evolución sube versión propia.

## Fases

### FASE 1 — Portada con planeta digital + flujo de entrada (brief: splash, cobertura)
- `NexoraPlanet` (CustomPainter animado, sin assets, RepaintBoundary, posiciones
  determinísticas): planeta digital oscuro, anillos dorado/azul en órbita,
  puntos orbitales, campo de estrellas con parpadeo.
- Nueva portada (reemplaza el arranque y la puerta): planeta + NEXORA +
  SEGURIDAD + eslogan + botones `INICIAR SESIÓN` / `CREAR CUENTA`.
- Flujo: AuthGate → portada → (botón) → AuthScreen en modo signIn/signUp.
- El splash post-login de la shell gana el fondo del planeta (conserva
  `COMENZAR` / `VER CÓMO FUNCIONA`).

### FASE 2 — Tema apagado (brief: colores)
- Paleta recargada a tonos apagados y elegantes: negro, azul oscuro,
  azul grisáceo, gris, rojo vino, dorado MUY sutil. Fondo casi negro,
  superficies desaturadas, acentos reducidos.

### FASE 3 — Autenticación completa (brief: login, registro, sesión, recupero)
- `AuthStore`: `rememberMe` (sin él la sesión NO se persiste: vive solo en
  esta ejecución), perfil (nombre, usuario, avatar), término/año.
- Registro: foto opcional (pickImage nativo ya existente), nombre, usuario,
  email, contraseña, confirmación, checkbox de términos; validaciones claras.
- Login: `Recordarme`, link a registro, link a recupero.
- Recupero: ARQUITECTURA PREPARADA (`PasswordRecoveryService` interfaz +
  impl local honesta). Sin backend no se manda nada: pantalla que explica
  que la recuperación requiere el servicio (futuro), sin enlace falso.
- Pantallas con el planeta de fondo y tema v2.

### FASE 4 — Gráfica central unificada e interactiva (brief: gráfica, métricas)
- `NexoraInteractiveChart`: múltiples métricas (SEGURIDAD, BATERÍA,
  TEMPERATURA, CPU, RAM, RED) en una sola gráfica con:
  - conmutador de series (TODAS o una),
  - ventanas de tiempo 1H / 6H / 24H / 7D,
  - tooltip al tocar un punto (valor + hora),
  - datos 100% reales del historial sellado.
- Dona interactiva de seguridad con segmentos TOQUEABLES que navegan a
  pantallas reales (apps → apps/veredictos, red → network, etc.).

### FASE 5 — CPU real (brief: méis métricas honestas)
- Lectura real de CPU en Kotlin vía `/proc/stat` (muestreo delta en el
  `collect`); si la plataforma no lo expone, la serie se oculta y se dice
  la verdad. `HistoryRow` gana `cpuUsedPercent` + `cpuPercentAvailable`,
  `batteryPercent` y red. `snapshot_json` suma los campos nuevos sin subir
  `schemaVersion` (política de esquema documentada).

### FASE 6 — NEXORA PLAY (brief: juegos, puntajes, logros)
- Hub de juegos con 4 minijuegos Dart puros (CustomPainter; sin assets):
  Cyber Minesweeper, Cyber Chess (reglas clásicas simplificadas, honestidad
  en la etiqueta), Firewall, Phishing Detector.
- `ScoreStore` + `AchievementsStore` (JSON local; logros que se desbloquean
  con hechos reales, no inventados). Puntajes altos por juego.

### FASE 7 — Navegación conectada (brief: pestañas, navegación)
- Pestaña PLAY añadida a la barra inferior (se preservan los índices 0–4).
- Tarjetas y métricas del Inicio TOQUEABLES → pantallas reales.

### FASE 7b — Modificación 2026-09 (spec del cliente)
- Fondo de constelación animada (`NexoraConstellation`) en Home/cover.
- Recuperación offline real: 4 pasos email → código local visible (honesto,
  sin red) → nueva contraseña → login. `AuthStore.resetPassword`.
- Perfil real: edición persistida (`updateProfile`) y "Cambiar contraseña"
  desde el Perfil (`changePassword` con salt regenerado).
- Dona del Inicio: % de salud compuesta REAL en el centro (memoria,
  almacenamiento, batería, CPU y red ponderados) + "sensores activos/totales".
- Gráfica interactiva: arrastre para seguir el punto, estadísticas
  máx/mín/prom y variación "última vs inicial".
- Análisis avanzado: 4 vistas animadas (onda/área/barras/dispersión) con
  datos reales del historial.
- Tests nuevos: f7_auth_security, f7_analysis, f7_profile_ui. Suite ~270 verde.

### FASE 8 — Perfil, IA contextual y premium (brief: perfil, IA, premium)
- Perfil: nombre/usuario/email/avatar editables, sesión actual, logout,
  resumen de logros y puntajes.
- Nexora AI contextual por pantalla (recibe el contexto de la pestaña activa).
- Premium: precio configurado desde una única fuente (ya centralizado);
  se verifica que ninguna pantalla duplique el valor.

### FASE 9 — i18n ×5, responsive y rendimiento
- Traducciones completas de lo nuevo; `NexoraMaxWidth` en pantallas nuevas;
  animaciones con `RepaintBoundary` y sin alocaciones por frame.

### FASE 8 spec 2.2.0 (modificación 2026-09)
- Splash → puerta de cuentas: el botón COMENZAR lleva a AuthScreen cuando
  no hay sesión (el AuthGate primario queda como respaldo).
- Contraseñas fuertes de verdad: política única (8+ con mayúscula, minúscula
  y número) en registro, cambio y recupero, con checklist en vivo recalculado
  al escribir y verificación humana obligatoria para crear la cuenta.
- Dona de salud: centro = % real tappable que abre la escala de colores; el
  centro NO roba los toques del anillo (los arcos siguen navegando).
- Ajustes por grupos (Cuenta/Seguridad/Aplicación) desde el engranaje, con
  acceso a cambio de contraseña, notificaciones, permisos de apps,
  protección, plan BASIC/PROFESSIONAL, preferencias y acerca de.
- Centro de notificaciones in-app persistente (`nexora-feed.json`):
  feed con severidad real, lectura, badge de no leídas, "marcar todas leídas"
  y TopBar con indicador de recarga animado en SafeArea.
- Sección APLICACIONES dentro de Protección (nivel de riesgo + estado de
  permisos reales) y detalle de alertas con explicación honesta.
- Renombre de plan a BASIC/PROFESSIONAL en toda la app y en pruebas (BÁSICO,
  PREMIUM y COMENZAR PREMIUM quedan obsoletos).
- Primer inicio de sesión: se pide permiso de notificaciones una sola vez.
- QA: 270 tests verdes, `flutter analyze` limpio (1 info preexistente de
  v2.1.0), APK release firmado `2.2.0+16`.

### FASE 10 — QA, versión y entrega
- Suite completa verde, `flutter analyze` sin errores, APK firmado nuevo,
  tag + release en GitHub.

## Estado

- [x] FASE 1 — portada/planeta/flujo
- [x] FASE 2 — tema apagado
- [x] FASE 3 — auth completo
- [x] FASE 4 — gráfica interactiva + dona
- [x] FASE 5 — CPU real
- [x] FASE 6 — PLAY + score + logros
- [x] FASE 7 — navegación conectada
- [x] FASE 7b — modificación 2026-09 (fondo constelación, recuperación,
  perfil real + contraseña, dona con salud real, gráficas avanzadas)
- [ ] FASE 8 — perfil/IA/premium
- [ ] FASE 9 — i18n/responsive/rendimiento
- [ ] FASE 10 — QA/versión/entrega