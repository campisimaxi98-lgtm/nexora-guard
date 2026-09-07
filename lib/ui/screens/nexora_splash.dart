/// Pantalla de bienvenida (splash) — primer contacto visual con NEXORA.
///
/// Ahora ES la puerta de entrada real: `COMENZAR` abre la autenticación
/// local si la sesión está cerrada, o entra directo si la sesión ya está
/// activa (FASE 8). La cuenta vive 100 % en el dispositivo (sin servidor —
/// ver `core/auth_store.dart`); NO se ofrece un login remoto que no existe.
/// El flujo invite de "VER CÓMO FUNCIONA" se retiró: la app no improvisa
/// demos, solo hay datos reales.
library;

import 'package:flutter/material.dart';

import '../../meta.dart';
import '../components.dart';
import '../nexora_logo.dart';
import '../theme.dart';

class NexoraSplashScreen extends StatelessWidget {
  const NexoraSplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    body: Stack(
      children: [
        // Planeta digital detrás, tenue para no competir con la marca.
        Positioned.fill(
          child: Opacity(
            opacity: 0.55,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 720,
                height: 720,
                child: NexoraPlanet(size: 720),
              ),
            ),
          ),
        ),
        SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 3),
            const NexoraLogo(size: 168),
            const SizedBox(height: 22),
            Text(
              Meta.suiteName,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: nexoraGoldLight,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'S E C U R I T Y',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: nexoraWine,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tu seguridad digital,',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const Text(
              'nuestra misión.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE05263),
              ),
            ),
            const Spacer(flex: 4),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nexoraGold,
                  foregroundColor: nexoraBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                onPressed: onContinue,
                child: const Text('COMENZAR'),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            const Text(
              'Protegemos lo que más importa.',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
        ),
      ],
    ),
  );
}
