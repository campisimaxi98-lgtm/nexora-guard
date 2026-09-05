/// Portada de NEXORA GUARD — primer contacto visual del ecosistema.
///
/// Planeta digital animado de fondo (componente [NexoraPlanet]), la marca
/// en grande, el eslogan y dos accesos: `INICIAR SESIÓN` y `CREAR CUENTA`.
/// No hace nada por su cuenta: las acciones las decide el llamador
/// ([AuthGate] en `main.dart`) según el flujo de sesión.
library;

import 'package:flutter/material.dart';

import '../components.dart';
import '../strings.dart';
import '../theme.dart';

class NexoraCoverScreen extends StatelessWidget {
  const NexoraCoverScreen({
    super.key,
    required this.strings,
    this.fixedSize = 640,
    this.onSignIn,
    this.onSignUp,
    this.busy = false,
  });

  final AppStrings strings;
  final double fixedSize;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignUp;

  /// Arranque en curso: los botones aparecen pero quedan deshabilitados.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Scaffold(
      backgroundColor: nexoraBackground,
      body: Stack(
        children: [
          // Planeta cubriendo el fondo (se reescala sin deformarse).
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: fixedSize,
                height: fixedSize,
                child: NexoraPlanet(size: fixedSize, slow: !busy),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.82, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Transform.scale(
                      scale: t,
                      child: Opacity(opacity: t, child: child),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: nexoraGoldLight,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'S E C U R I T Y',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 7,
                            color: nexoraBlue,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '🛡',
                          style: TextStyle(fontSize: 26, color: nexoraWine),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.coverSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      letterSpacing: 0.4,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.coverSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: nexoraGold,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: nexoraGold,
                        foregroundColor: nexoraBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: busy ? null : onSignIn,
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: Text(s.authSignIn),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: nexoraBorder, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: busy ? null : onSignUp,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                      label: Text(s.authSignUp),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${s.createdBy} ${nexoraCreatorName.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: nexoraGold.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}