/// Componentes reutilizables del sistema de diseño v2 (FASE 3).
///
/// Piezas atómicas que las fases siguientes (dashboard, apps, señales,
/// perfil, premium) combinan sin reinventar forma ni colores. No duplican
/// los widgets de `ui/widgets.dart` (métricas animadas, dona, radar…): la
/// regla es *componer* sobre ellos.
library;

import 'package:flutter/material.dart';

import '../../core/app_risk_level.dart';
import '../theme.dart';
import 'nexora_tokens.dart';

/// Color de cada nivel de riesgo. El nivel NUNCA se comunica solo por color:
/// [LevelBadge] siempre incluye la etiqueta de texto (accesibilidad, regla 32).
Color riskLevelColor(AppRiskLevel level) => switch (level) {
  AppRiskLevel.safe => severityGreen,
  AppRiskLevel.attention => severityYellow,
  AppRiskLevel.suspicious => nexoraOrange,
  AppRiskLevel.critical => nexoraRed,
};

IconData riskLevelIcon(AppRiskLevel level) => switch (level) {
  AppRiskLevel.safe => Icons.verified_user,
  AppRiskLevel.attention => Icons.visibility_outlined,
  AppRiskLevel.suspicious => Icons.error_outline,
  AppRiskLevel.critical => Icons.gpp_bad,
};

/// Tarjeta base "glass": cualquier contenido con superficie elevada.
class NexoraCard extends StatelessWidget {
  const NexoraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ntPad),
    this.color = nexoraSurface,
    this.glow = false,
    this.onTap,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool glow;
  final VoidCallback? onTap;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final decoration = ntGlass(
      radius: radius ?? ntRadiusCard,
      tint: color,
      glow: glow,
    );
    // Material+Ink SIEMPRE (también sin onTap): un ListTile dentro de la
    // tarjeta necesita un Material sobre el que pintar tinta y colores, o
    // Flutter lo reclama en debug/tests.
    final content = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius ?? ntRadiusCard),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Encabezado de sección: ícono + título + área opcional al final (badge,
/// "VER MÁS", chips…).
class SectionHeaderRow extends StatelessWidget {
  const SectionHeaderRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor = nexoraGoldLight,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ntRadiusSmall),
        ),
        child: Icon(icon, size: 17, color: iconColor),
      ),
      const SizedBox(width: ntGapSmall),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ?trailing,
    ],
  );
}

/// Fila métrica: ícono, etiqueta, valor y barra de progreso opcional (0..1),
/// como las barras de actividad del dashboard (CPU/RAM/red).
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.barValue,
    this.color = nexoraGold,
    this.semanticsText,
  });

  final IconData icon;
  final String label;
  final String value;
  final double? barValue;
  final Color color;
  final String? semanticsText;

  @override
  Widget build(BuildContext context) {
    final bar = (barValue ?? 0.0).clamp(0.0, 1.0);
    final row = Semantics(
      label: semanticsText ?? '$label $value',
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: ntGapSmall),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    if (barValue == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(ntRadiusPill),
          child: LinearProgressIndicator(
            value: bar,
            minHeight: 5,
            backgroundColor: nexoraBorder.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Píldora de nivel de riesgo: ícono + etiqueta + color, SIEMPRE con texto
/// (accesibilidad: no depender del color como única señal).
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    required this.label,
    this.compact = false,
  });

  final AppRiskLevel level;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ntRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskLevelIcon(level), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de bloqueo premium: lo que muestran las zonas gated en vez de
/// simular el contenido. El CTA abre la pantalla de suscripción.
class PremiumLockedCard extends StatelessWidget {
  const PremiumLockedCard({
    super.key,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onViewPremium,
  });

  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onViewPremium;

  @override
  Widget build(BuildContext context) => NexoraCard(
    glow: true,
    padding: const EdgeInsets.all(ntPad),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline, color: nexoraGoldLight, size: 18),
            const SizedBox(width: ntGapSmall),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: nexoraGoldLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: ntGapSmall),
        Text(description, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: ntPadSmall),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onViewPremium,
            icon: const Icon(Icons.star_border, size: 16),
            label: Text(ctaLabel),
          ),
        ),
      ],
    ),
  );
}

/// Ancho máximo para tabletas y pantallas grandes: el contenido se centra
/// en una columna legible en vez de estirarse.
class NexoraMaxWidth extends StatelessWidget {
  const NexoraMaxWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}