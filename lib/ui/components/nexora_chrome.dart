/// Chrome de la shell v2: barra superior y el botón flotante de Nexora AI.
library;

import 'package:flutter/material.dart';

import '../nexora_logo.dart';
import '../theme.dart';
import 'nexora_tokens.dart';

/// Barra superior de las pantallas principales:
/// `NEXORA` a la izquierda, y a la derecha campana (con badge de alertas) y
/// engranaje (Configuración). Además un refresh opcional para el Inicio.
class NexoraTopBar extends StatelessWidget {
  const NexoraTopBar({
    super.key,
    this.alertCount = 0,
    required this.onOpenAlerts,
    required this.onOpenSettings,
    this.onRefresh,
    this.refreshEnabled = true,
  });

  final int alertCount;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenSettings;
  final VoidCallback? onRefresh;
  final bool refreshEnabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(ntPad, 6, ntPad, 0),
    child: Row(
      children: [
        const NexoraLogo(size: 30, showRing: false),
        const SizedBox(width: 8),
        const Text(
          'NEXORA',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: nexoraGoldLight,
          ),
        ),
        const Spacer(),
        if (onRefresh != null)
          IconButton(
            onPressed: refreshEnabled ? onRefresh : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        IconButton(
          onPressed: onOpenAlerts,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none),
              if (alertCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: nexoraRed,
                      borderRadius: BorderRadius.circular(ntRadiusPill),
                    ),
                    child: Text(
                      alertCount > 99 ? '99+' : '$alertCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Alerts',
        ),
        IconButton(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
    ),
  );
}

/// Botón flotante de Nexora AI: nube dorada con pulso sutil y rebote lento.
/// Es una pieza de navegación — abre el chat vía [onTap].
class FloatingAIButton extends StatefulWidget {
  const FloatingAIButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    final glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return Semantics(
      button: true,
      label: widget.tooltip ?? 'NEXORA AI',
      child: ScaleTransition(
        scale: scale,
        child: Opacity(
          opacity: 0.85 + glow.value * 0.15,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [nexoraGoldLight, nexoraGold, nexoraBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: nexoraGold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: glow.value * 4,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: nexoraBackground,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}