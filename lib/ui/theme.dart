/// Tema Material 3 — identidad NEXORA aplicada a la paleta "apagada":
/// negro, azul oscuro, azul grisáceo, gris, rojo vino y dorado MUY sutil.
/// Los acentos existen pero ya no gritan: superficies mates, bordes vinosos
/// y dorado reservado para lo premium y la información clave.
library;

import 'package:flutter/material.dart';

import '../core/models.dart';

/// Colores oficiales NEXORA (gama apagada del ecosistema).
const nexoraGold = Color(0xFFA98F53); // dorado sutil: premium e información clave
const nexoraGoldLight = Color(0xFFC9B98C);
const nexoraBlue = Color(0xFF5A6B82); // azul grisáceo: tecnología e IA
const nexoraRed = Color(0xFFA63D34); // rojo vino apagado: peligro, alerta
const nexoraBackground = Color(0xFF070A11); // negro con un leve azul profundo
const nexoraSurface = Color(0xFF12161F); // gris azulado muy oscuro

// Tokens auxiliares usados por las pantallas de la shell NEXORA
// (dashboard/bot/perfil): superficie elevada, borde sutil y acento vino.
const nexoraSurfaceRaised = Color(0xFF1B212C);
const nexoraBorder = Color(0xFF2C3440);
const nexoraWine = Color(0xFF6E2B45);

// Naranja: nivel "sospechoso" (entre atención-dorado y crítico-rojo),
// también apagado para mantener la gama.
const nexoraOrange = Color(0xFFC0743C);

// Severidad de hallazgos, mapeada a la paleta NEXORA.
// Verde solo como indicador secundario (estado "normal").
const severityGreen = Color(0xFF3A8A5C);
const severityYellow = nexoraGold;
const severityRed = nexoraRed;

Color severityColor(Severity s) => switch (s) {
  Severity.normal => severityGreen,
  Severity.warning => severityYellow,
  Severity.critical => severityRed,
};

/// Transición estándar de la app: deslizamiento con desvanecido hacia
/// adelante en todas las plataformas — movimiento consistente y sobrio.
const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
  },
);

ThemeData nexoraDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  pageTransitionsTheme: _pageTransitions,
  colorScheme: ColorScheme.fromSeed(
    seedColor: nexoraBlue,
    brightness: Brightness.dark,
    primary: nexoraGold,
    secondary: nexoraBlue,
    error: nexoraRed,
    surface: nexoraSurface,
  ),
  scaffoldBackgroundColor: nexoraBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: nexoraBackground,
    foregroundColor: nexoraGoldLight,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: nexoraSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: nexoraGold,
      foregroundColor: nexoraBackground,
    ),
  ),
);

// NEXORA GUARD se diseñó como app oscura por defecto (mejor legibilidad
// para el público objetivo y coherencia con la identidad visual), pero
// se mantiene un tema claro de respaldo por si el sistema lo solicita.
ThemeData nexoraLightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  pageTransitionsTheme: _pageTransitions,
  colorScheme: ColorScheme.fromSeed(
    seedColor: nexoraBlue,
    brightness: Brightness.light,
    primary: nexoraBlue,
    error: nexoraRed,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F8FA),
);
