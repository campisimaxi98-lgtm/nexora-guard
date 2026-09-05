# Roadmap — Rediseño Nexora Guard (v2.0)

Objetivo: transformar Nexora Guard en un producto de ciberseguridad
moderno, futurista, interactivo y comercializable, **sin romper** la base
v1.0.0 publicada (143 tests, 5 idiomas, cero internet garantizado por CI).

Metodología (sección 42 del brief): una fase por vez → compilar → ejecutar →
corregir → verificar que lo anterior sigue verde.

## Estado de partida (FASE 1 — análisis, completada)

- V1.0.0 vive en `main.dart` con `TabBar` clásico (10 pestañas según modo),
  colección real de snapshot, motor de reglas, historial encadenado SHA-256,
  PDF forense, respaldo/restauración, BLE cercanía, worker de fondo + widget,
  cuenta local, radar/dona/tendencia interactivas. 143 tests verdes.
- WIP `lib/ui/screens/nexora_*.dart` del commit `92b875c`: un shell de 5
  pestañas (Inicio/Análisis/Protección/Alertas/Perfil), dashboard, quickscan,
  análisis de apps, chat local con reglas — **NUNCA se montó** en `main.dart`
  y tiene textos hardcodeados en español (rompe la i18n de 5 idiomas).
- Decide del rediseño: adoptar el concepto del shell WIP, reconstruido sobre
  la base v1.0.0 sólida (i18n real, datos reales, honestidad, tests).

## Fases

| Fase | Alcance | Estado |
|---|---|---|
| 1 | Análisis completo del proyecto | ✅ |
| 2 | Arquitectura: `AppRiskLevel` (4 niveles), `NexoraSubscription` + servicio + `PaymentsProvider`, `NexoraAIEngine` local contextual | ✅ |
| 3 | Sistema de diseño: tokens de superficie, `NexoraCard`, `SectionHeaderRow`, `ValueRow`, `LevelBadge`, `PremiumLockedCard`, `NexoraMaxWidth`, `NexoraTopBar`, `FloatingAIButton` | ✅ |
| 4 | Dashboard futurista: escudo de seguridad, batería/temperatura, barras RAM/red reales (CPU dice la verdad), señales, apps, VER ANÁLISIS | ✅ |
| 5 | Apps: clasificación 4 niveles, tarjetas compactas agrupadas + búsqueda, detalle con permisos interactivos + deep links reales a Ajustes | ✅ |
| 6 | Señales: filtros TODAS/RED/PERMISOS/BATERÍA/CPU/RAM/ACTIVIDAD/RIESGO, ocultar inactivas, MOSTRAR TODAS | ⏳ |
| 7 | Gráficas: historial batería/temperatura, consumo honesto por app, dona de almacenamiento real | ⏳ |
| 8 | Perfil: foto real (selector nativo), nombre/usuario editables y validados, plan, estadísticas de protección | ⏳ |
| 9 | Nexora AI: chatbot flotante conectado al motor contextual local | ⏳ |
| 10 | Premium: pantalla de suscripción, gating, restauración, proveedor de pagos enchufable (sin pagos falsos) | ⏳ |
| 11 | Navegación: bottom nav 5 pestañas + TopBar (campana/engranaje), Configuración como pantalla | ⏳ |
| 12 | Rendimiento: RepaintBoundary, const, evitar rebuilds | ⏳ |
| 13 | Estados UI: loading / empty / error / offline / sin-permisos / premium-locked | ⏳ |
| 14 | Responsive (teléfonos y tablets) + accesibilidad (label+color, contraste, tamaño táctil) | ⏳ |
| 15 | Test completo + build release + reseñar release v2.0.0 | ⏳ |

## Reglas innegociables

1. **Cero internet en el flavor offline** (permiso INTERNET ausente, verificado
   por `scripts/check-no-internet.sh`). La IA es 100% local; la única salida de
   red es el flavor `connected` con consentimiento explícito.
2. **Nunca mentir**: un permiso no concedido no se presenta como riesgo real;
   una desactivación simulada está prohibida → redirigir a Ajustes del sistema.
3. **Nada de "malware" sin evidencia**: solo niveles 📶 SEGURO / ATENCIÓN /
   SOSPECHOSO / CRÍTICO con la evidencia que los sustenta.
4. **Cero dependencias externas** nuevas (regla del pubspec): todo con CustomPainter
   y APIs del SDK.
5. **5 idiomas** (es/en/pt/it/fr) en toda pantalla nueva; nada hardcodeado.
6. Cada fase termina con `flutter analyze` limpio + `flutter test` verde.
7. El modelo no ve imágenes: los assets de tienda se validan por dimensiones.

## Nota de versionado

En la fase final se hace bump a `2.0.0+X` en `pubspec.yaml` + `CHANGELOG.md` +
tag + release con AAB/APKs firmados (mismo flujo que v1.0.0).