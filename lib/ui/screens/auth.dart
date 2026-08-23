/// Pantalla de bienvenida de NEXORA GUARD — identidad visual y puerta local.
///
/// Es la primera pantalla que ve quien abre la app: el escudo NEXORA en
/// grande sobre fondo profundo, con anillos concéntricos en deriva lenta.
/// Ofrece dos modos: crear la cuenta local del teléfono o iniciar sesión si
/// ya existe. Todo ocurre sin red: la cuenta vive únicamente en este equipo
/// (ver `core/auth_store.dart`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/auth_store.dart';
import '../nexora_logo.dart';
import '../strings.dart';
import '../theme.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.strings,
    required this.store,
    required this.onAuthenticated,
  });

  final AppStrings strings;
  final AuthStore store;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.signUp;

  // Si ya existe una cuenta registrada, el modo natural es iniciar sesión.
  @override
  void initState() {
    super.initState();
    if (widget.store.account != null) _mode = _AuthMode.signIn;
  }

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  String? _error;

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final s = widget.strings;
    if (!_formKey.currentState!.validate()) return;
    if (_mode == _AuthMode.signUp && _confirm.text != _password.text) {
      setState(() => _error = s.authErrMismatch);
      return;
    }
    setState(() => _error = null);
    // Operación local y síncrona (un JSON minúsculo): sin esperas visibles.
    final result = _mode == _AuthMode.signUp
        ? widget.store.register(_email.text, _password.text)
        : widget.store.login(_email.text, _password.text);
    switch (result) {
      case AuthResult.ok:
        widget.onAuthenticated();
      case AuthResult.emailTaken:
        setState(() {
          _error = s.authErrEmailTaken;
          _mode = _AuthMode.signIn;
        });
      case AuthResult.wrongCredentials:
        setState(() => _error = s.authErrWrongCredentials);
      case AuthResult.weakPassword:
        setState(() => _error = s.authErrWeakPassword);
      case AuthResult.invalidEmail:
        setState(() => _error = s.authErrInvalidEmail);
      case AuthResult.storage:
        setState(() => _error = s.restoreFail);
    }
  }

  String? _validateEmail(String? value) =>
      (value ?? '').trim().isEmpty ? widget.strings.authErrInvalidEmail : null;

  String? _validatePassword(String? value) =>
      (value ?? '').length < 6 ? widget.strings.authErrWeakPassword : null;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final wide = MediaQuery.sizeOf(context).width;
    final cardWidth = wide < 480 ? double.infinity : 420.0;

    return Scaffold(
      backgroundColor: nexoraBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) =>
                  CustomPaint(painter: _BackdropPainter(drift: _drift.value)),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) => Transform.scale(
                        scale: t,
                        child: Opacity(opacity: t.clamp(0, 1), child: child),
                      ),
                      child: const HeroShield(),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [nexoraGoldLight, nexoraGold],
                      ).createShader(bounds),
                      child: Text(
                        'NEXORA',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 14 / 40 * wide.clamp(320, 480) / wide,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'G U A R D',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 10,
                        color: nexoraBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.authTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(width: cardWidth, child: _card(context)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.authLocalNote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Crédito de autoría, siempre visible en la puerta de entrada.
                    Text(
                      '${s.createdBy} ${nexoraCreatorName.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: nexoraGold.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context) {
    final s = widget.strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nexoraSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: nexoraGold.withValues(alpha: 0.25)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_AuthMode>(
              segments: [
                ButtonSegment(
                  value: _AuthMode.signIn,
                  label: Text(s.authSignIn),
                ),
                ButtonSegment(
                  value: _AuthMode.signUp,
                  label: Text(s.authSignUp),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() {
                _mode = selection.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              decoration: InputDecoration(
                labelText: s.authEmail,
                prefixIcon: const Icon(Icons.mail_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              validator: _validatePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: s.authPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _mode == _AuthMode.signUp
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        validator: (v) =>
                            v != _password.text ? s.authErrMismatch : null,
                        decoration: InputDecoration(
                          labelText: s.authConfirmPassword,
                          prefixIcon: const Icon(Icons.repeat_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: nexoraRed, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: nexoraRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(
                _mode == _AuthMode.signUp
                    ? Icons.person_add_alt_1_rounded
                    : Icons.login_rounded,
              ),
              label: Text(
                _mode == _AuthMode.signUp
                    ? s.authCreateButton
                    : s.authEnterButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El escudo grande de la bienvenida: el mismo dibujo del launcher, ahora
/// protagonista, con un halo dorado suave detrás.
class HeroShield extends StatelessWidget {
  const HeroShield({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 190,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: nexoraGold.withValues(alpha: 0.35),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        const NexoraLogo(size: 190, showRing: false),
      ],
    ),
  );
}

/// Fondo ambiental: resplandores dorado/azul, estrellas tenues y anillos
/// concéntricos en deriva muy lenta (`drift` va de 0 a 1 en ~36 s).
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.drift});

  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.26);

    final goldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          nexoraGold.withValues(alpha: 0.16),
          nexoraGold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawRect(Offset.zero & size, goldGlow);

    final blueGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              nexoraBlue.withValues(alpha: 0.20),
              nexoraBlue.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 1.05),
              radius: size.width * 0.9,
            ),
          );
    canvas.drawRect(Offset.zero & size, blueGlow);

    // Estrellas fijas: posiciones determinísticas para no parpadear entre
    // frames (mismo seed → mismos puntos siempre).
    final star = Paint()..color = Colors.white;
    var i = 0;
    for (final (x, y) in _stars) {
      final twinkle =
          0.10 + 0.08 * (0.5 + 0.5 * math.sin((drift * 6.2832 * 3) + i * 1.7));
      star.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(Offset(size.width * x, size.height * y), 1.1, star);
      i++;
    }

    // Anillos concéntricos girando alrededor del escudo.
    final ringCenter = Offset(size.width * 0.5, size.height * 0.26);
    for (var r = 0; r < 3; r++) {
      final radius = 120.0 + r * 52.0;
      final sweep = 3.6 - r * 0.7;
      final start = drift * 6.2832 * (r.isEven ? 1 : -1) + r * 0.9;
      canvas.drawArc(
        Rect.fromCircle(center: ringCenter, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = (r.isEven ? nexoraGold : nexoraBlue).withValues(
            alpha: 0.22,
          ),
      );
    }
  }

  static const _stars = [
    (0.08, 0.12),
    (0.18, 0.32),
    (0.30, 0.08),
    (0.44, 0.18),
    (0.62, 0.06),
    (0.74, 0.22),
    (0.88, 0.12),
    (0.93, 0.34),
    (0.12, 0.55),
    (0.85, 0.58),
    (0.06, 0.78),
    (0.24, 0.88),
    (0.50, 0.94),
    (0.76, 0.86),
    (0.95, 0.80),
    (0.65, 0.75),
    (0.35, 0.68),
    (0.90, 0.46),
    (0.05, 0.40),
    (0.55, 0.30),
  ];

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.drift != drift;
}
