/// Pantalla de bienvenida (splash) — primer contacto visual con NEXORA.
///
/// Nota honesta: NEXORA GUARD no tiene backend de cuentas ni autenticación
/// (todo el análisis vive en el propio dispositivo, sin servidor — ver
/// `HistoryStore`/`ConfigStore`, ambos locales). Los botones "Iniciar
/// sesión" / "Crear cuenta" del diseño original implicaban una cuenta
/// remota; acá ambos simplemente continúan hacia la app, porque no existe
/// (ni se simula) un sistema de login real.
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: nexoraBorder, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onContinue,
                child: const Text('VER CÓMO FUNCIONA'),
              ),
            ),
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
