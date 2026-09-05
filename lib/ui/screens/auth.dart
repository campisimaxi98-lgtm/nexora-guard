/// Puerta de cuenta de NEXORA GUARD — identidad visual y sesión local.
///
/// Es la primera pantalla funcional tras la portada: el escudo NEXORA sobre
/// el fondo profundo con el planeta digital tenue y anillos en deriva lenta.
/// Modos:
/// - Iniciar sesión: correo + contraseña + "Recordarme" (si NO está
///   marcado, la sesión dura solo este arranque) + acceso a recupero.
/// - Crear cuenta: foto opcional, nombre, usuario, correo, contraseña,
///   confirmación y aceptación de términos.
/// Todo ocurre sin red: la cuenta vive únicamente en este equipo
/// (ver `core/auth_store.dart`). La recuperación de contraseña es
/// arquitectura preparada (ver `core/password_recovery.dart`): sin
/// servicio remoto, responde con honestidad que nada se envía.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/auth_store.dart';
import '../../core/password_recovery.dart';
import '../components.dart';
import '../nexora_logo.dart';
import '../strings.dart';
import '../theme.dart';

enum _AuthMode { signIn, signUp }

/// Modo con el que abre la pantalla de cuenta (lo decide la portada).
enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.strings,
    required this.store,
    required this.onAuthenticated,
    this.initialMode,
    this.recovery = const LocalOfflineRecoveryService(),
    this.pickImage,
  });

  final AppStrings strings;
  final AuthStore store;
  final VoidCallback onAuthenticated;

  /// Si es null, el modo se deduce solo (cuenta existente → iniciar sesión).
  final AuthMode? initialMode;

  /// Proveedor de recupero; por defecto el local honesto (offline).
  final PasswordRecoveryService recovery;

  /// Selector de imagen nativa opcional (avatar del registro).
  final Future<Uint8List?> Function()? pickImage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late _AuthMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.initialMode) {
      AuthMode.signIn => _AuthMode.signIn,
      AuthMode.signUp => _AuthMode.signUp,
      // Si ya existe una cuenta registrada, el modo natural es iniciar sesión.
      null => widget.store.account != null
          ? _AuthMode.signIn
          : _AuthMode.signUp,
    };
  }

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();

  Uint8List? _avatar;
  bool _obscure = true;
  bool _rememberMe = true;
  bool _termsAccepted = false;
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
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = widget.pickImage;
    if (picker == null) return;
    final bytes = await picker();
    if (bytes != null && mounted) setState(() => _avatar = bytes);
  }

  void _openRecovery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecoveryScreen(strings: widget.strings, email: _email.text),
      ),
    );
  }

  void _submit() {
    final s = widget.strings;
    if (!_formKey.currentState!.validate()) return;
    if (_mode == _AuthMode.signUp) {
      if (_confirm.text != _password.text) {
        setState(() => _error = s.authErrMismatch);
        return;
      }
      if (!_termsAccepted) {
        setState(() => _error = s.authErrTerms);
        return;
      }
    }
    setState(() => _error = null);
    // Operación local y síncrona (un JSON minúsculo): sin esperas visibles.
    final result = _mode == _AuthMode.signUp
        ? widget.store.register(
            _email.text,
            _password.text,
            name: _name.text,
            username: _username.text,
            avatarBase64: _avatar == null ? '' : _avatarBase64(),
            rememberMe: _rememberMe,
          )
        : widget.store.login(
            _email.text,
            _password.text,
            rememberMe: _rememberMe,
          );
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

  /// Base64 sin prefijo del avatar elegido (mismo formato que el del
  /// colector nativo); en un test sin imágenes reales queda vacío.
  String _avatarBase64() {
    final bytes = _avatar;
    if (bytes == null || bytes.isEmpty) return '';
    // Sin `dart:convert` en este archivo de UI: se delega el encode al
    // núcleo (archivo compartido) para no duplicar primitivas.
    return avatarToBase64(bytes);
  }

  String? _validateEmail(String? value) =>
      (value ?? '').trim().isEmpty ? widget.strings.authErrInvalidEmail : null;

  String? _validatePassword(String? value) =>
      (value ?? '').length < 8 ? widget.strings.authErrWeakPassword : null;

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3 || RegExp(r'\s').hasMatch(v)) {
      return widget.strings.authErrUsername;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final wide = MediaQuery.sizeOf(context).width;
    final cardWidth = wide < 480 ? double.infinity : 420.0;

    return Scaffold(
      backgroundColor: nexoraBackground,
      body: Stack(
        children: [
          // Planeta digital tenue detrás de todo (clima del ecosistema).
          Positioned.fill(
            child: Opacity(
              opacity: 0.28,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 900,
                  height: 900,
                  child: NexoraPlanet(size: 900),
                ),
              ),
            ),
          ),
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
    final isSignUp = _mode == _AuthMode.signUp;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nexoraSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: nexoraGold.withValues(alpha: 0.22)),
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
            const SizedBox(height: 16),
            if (isSignUp) _avatarRow(s),
            if (isSignUp) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _username,
                textCapitalization: TextCapitalization.none,
                validator: _validateUsername,
                decoration: InputDecoration(
                  labelText: s.authUsername,
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: s.authName,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
            ],
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
              child: isSignUp
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
            if (isSignUp)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v ?? false),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.authTerms,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.authRememberMe,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
              ),
              label: Text(isSignUp ? s.authCreateButton : s.authEnterButton),
            ),
            if (!isSignUp) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _openRecovery,
                child: Text(
                  s.authForgotPassword,
                  style: const TextStyle(
                    color: nexoraGoldLight,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatarRow(AppStrings s) {
    final picker = widget.pickImage;
    return Row(
      children: [
        GestureDetector(
          onTap: picker == null ? null : _pickAvatar,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: nexoraBorder.withValues(alpha: 0.6),
            foregroundImage: _avatar == null
                ? null
                : Image.memory(_avatar!).image,
            child: _avatar == null
                ? Icon(
                    Icons.photo_camera_outlined,
                    color: nexoraGoldLight,
                    size: 22,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: TextButton(
            onPressed: picker == null ? null : _pickAvatar,
            child: Text(s.authAvatarLabel),
          ),
        ),
      ],
    );
  }
}

/// Pantalla de REcuperación de contraseña — honesta por diseño.
///
/// Sin backend (offline) NO se envía nada: la pantalla explica que el
/// servicio de envío aún no existe y que la arquitectura ya lo contempla,
/// según [PasswordRecoveryService]. Nunca simula un enlace, un correo ni
/// una operación exitosa que no ocurrió.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, required this.strings, this.email});

  final AppStrings strings;
  final String? email;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  static const _service = LocalOfflineRecoveryService();
  late final TextEditingController _email = TextEditingController(
    text: widget.email ?? '',
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    // Operación honesta: el servicio local responde "no configurado".
    _service.requestReset(_email.text.trim()).then((result) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == PasswordRecoveryResult.ok
                ? widget.strings.authRecoverSent
                : widget.strings.authRecoverNote,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      backgroundColor: nexoraBackground,
      appBar: AppBar(
        backgroundColor: nexoraBackground,
        foregroundColor: nexoraGoldLight,
        title: Text(s.authRecoverTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.key_off_outlined, color: nexoraGold, size: 46),
            const SizedBox(height: 16),
            Text(
              s.authRecoverTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.authRecoverBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(s.authRecoverSend),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: nexoraSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nexoraBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: nexoraOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.authRecoverNote,
                      style: const TextStyle(fontSize: 12.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(s.authRecoverBack),
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
          nexoraGold.withValues(alpha: 0.14),
          nexoraGold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawRect(Offset.zero & size, goldGlow);

    final blueGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              nexoraBlue.withValues(alpha: 0.18),
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