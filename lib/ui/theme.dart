/// Tema Material 3 — identidad NEXORA: dorado + azul + rojo sobre fondo oscuro.
library;

import 'package:flutter/material.dart';

import '../core/models.dart';

/// Colores oficiales NEXORA.
const nexoraGold = Color(0xFFC9A24B); // NEXORA BRAIN, información importante
const nexoraGoldLight = Color(0xFFE8C675);
const nexoraBlue = Color(0xFF3A6EA5); // Tecnología, IA, protección, sistema
const nexoraRed = Color(0xFFC0392B); // Peligro, estafa, alerta
const nexoraBackground = Color(0xFF0A0F24); // fondo azul muy oscuro/negro
const nexoraSurface = Color(0xFF12224A);

// Severidad de hallazgos, mapeada a la paleta NEXORA.
// Verde solo como indicador secundario (estado "normal").
const severityGreen = Color(0xFF2E9E5B);
const severityYellow = nexoraGold;
const severityRed = nexoraRed;

Color severityColor(Severity s) => switch (s) {
  Severity.normal => severityGreen,
  Severity.warning => severityYellow,
  Severity.critical => severityRed,
};

ThemeData nexoraDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
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
  colorScheme: ColorScheme.fromSeed(
    seedColor: nexoraBlue,
    brightness: Brightness.light,
    primary: nexoraBlue,
    error: nexoraRed,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F8FA),
);
