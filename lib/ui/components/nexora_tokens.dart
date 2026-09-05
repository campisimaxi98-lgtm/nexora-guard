/// Tokens de composición del sistema de diseño v2 — espaciado, radios y
/// superficies "glass" reutilizables en todas las pantallas nuevas.
///
/// Los colores de marca siguen viviendo en `ui/theme.dart`; acá va SOLO lo
/// mecánico (jerarquía y forma), para que ningún widget nuevo invente
/// radios/márgenes a mano.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

const ntRadiusCard = 16.0;
const ntRadiusSmall = 10.0;
const ntRadiusPill = 999.0;

const ntPad = 16.0;
const ntPadSmall = 12.0;
const ntGap = 12.0;
const ntGapSmall = 8.0;

/// Superficie elevada translúcida (glassmorphism moderado): oscura, con
/// borde sutil y sombra suave. `glow` agrega un halo de acento (premium/IA).
BoxDecoration ntGlass({
  double radius = ntRadiusCard,
  Color tint = nexoraSurface,
  bool glow = false,
  Color? border,
}) =>
    BoxDecoration(
      color: tint.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: border ?? nexoraBorder.withValues(alpha: 0.55),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        if (glow)
          BoxShadow(
            color: nexoraGold.withValues(alpha: 0.14),
            blurRadius: 22,
            spreadRadius: 1,
          ),
      ],
    );

/// Fondo degradado de tarjetas premium: vino → azul profundo con borde dorado.
BoxDecoration ntGlassPremium({double radius = ntRadiusCard}) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      nexoraWine.withValues(alpha: 0.55),
      nexoraSurfaceRaised.withValues(alpha: 0.7),
      nexoraBlue.withValues(alpha: 0.35),
    ],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: nexoraGold.withValues(alpha: 0.45)),
  boxShadow: [
    BoxShadow(
      color: nexoraGold.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ],
);