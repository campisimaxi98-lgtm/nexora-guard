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
    this.pickImage,
  });

  final AppStrings strings;
  final AuthStore store;
  final VoidCallback onAuthenticated;

  /// Si es null, el modo se deduce solo (cuenta existente → iniciar sesión).
  final AuthMode? initialMode;

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
        builder: (_) => RecoveryScreen(
          strings: widget.strings,
          store: widget.store,
          email: _email.text,
        ),
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
            const SizedBox(height: 2),
            TextButton(
              onPressed: () => setState(() {
                _mode = isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
                _error = null;
              }),
              child: Text(
                isSignUp ? s.authSwitchSignIn : s.authSwitchSignUp,
                style: const TextStyle(
                  color: nexoraGoldLight,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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

/// Pantalla de recuperación de contraseña (FASE 7) — flujo completo offline.
///
/// Pasos: email → código → nueva contraseña → listo. Sin red de verdad NO
/// existe el envío por correo: el código se genera localmente y se muestra
/// EN PANTALLA, con una nota que lo dice con honestidad (cuando NEXORA
/// GUARD tenga el servicio remoto, el mismo código viajará por email). El
/// restablecimiento escribe en [AuthStore.resetPassword] con salt nuevo.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({
    super.key,
    required this.strings,
    required this.store,
    this.email = '',
    this.codeGenerator,
  });

  final AppStrings strings;
  final AuthStore store;

  /// Email precargado (viene del campo de login).
  final String email;

  /// Generador de código inyectable (en pruebas se fija uno conocido).
  final String Function()? codeGenerator;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

enum _RecoveryStep { email, code, newPassword, done }

class _RecoveryScreenState extends State<RecoveryScreen> {
  late _RecoveryStep _step = _RecoveryStep.email;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  late String _generatedCode;
  String? _error;

  String _generateCode() =>
      widget.codeGenerator?.call() ??
      _sixDigits(
        DateTime.now().millisecondsSinceEpoch,
        math.Random().nextInt(0xFFFFFF),
      );

  static String _sixDigits(int a, int b) {
    final seed = (a ^ b).abs() | 0x1000000;
    return '$seed'.substring(1, 7);
  }

  void _nextFromEmail() {
    if (!_formKey.currentState!.validate()) return;
    final account = widget.store.account;
    final email = _email.text.trim().toLowerCase();
    if (account == null || account.email != email) {
      setState(() => _error = widget.strings.authRecoverErrorNoAccount);
      return;
    }
    setState(() {
      _error = null;
      _generatedCode = _generateCode();
      _step = _RecoveryStep.code;
    });
  }

  void _verifyCode() {
    if (_code.text.trim() != _generatedCode) {
      setState(() => _error = widget.strings.authRecoverCodeInvalid);
      return;
    }
    setState(() {
      _error = null;
      _code.clear();
      _step = _RecoveryStep.newPassword;
    });
  }

  void _regenerate() {
    setState(() {
      _generatedCode = _generateCode();
      _error = null;
    });
  }

  void _saveNewPassword() {
    if (!_formKey.currentState!.validate()) return;
    if (_confirm.text != _newPassword.text) {
      setState(() => _error = widget.strings.authErrMismatch);
      return;
    }
    final result = widget.store.resetPassword(_newPassword.text.trim());
    switch (result) {
      case AuthResult.ok:
        setState(() {
          _error = null;
          _step = _RecoveryStep.done;
        });
      case AuthResult.weakPassword:
        setState(() => _error = widget.strings.authErrWeakPassword);
      case AuthResult.storage:
        setState(() => _error = widget.strings.restoreFail);
      case AuthResult.invalidEmail:
      case AuthResult.emailTaken:
      case AuthResult.wrongCredentials:
        setState(() => _error = widget.strings.restoreFail);
    }
  }

  void _finish() => Navigator.of(context).pop();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              switch (_step) {
                _RecoveryStep.email => _emailStep(s),
                _RecoveryStep.code => _codeStep(s),
                _RecoveryStep.newPassword => _newPasswordStep(s),
                _RecoveryStep.done => _doneStep(s),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppStrings s, IconData icon, String title, String body) {
    return Column(
      children: [
        Icon(icon, color: nexoraGold, size: 44),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _errorRow() {
    final error = _error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: nexoraRed, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(error, style: const TextStyle(color: nexoraRed, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _emailStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s, Icons.mail_outline, s.authRecoverStepEmailTitle, s.authRecoverStepEmailBody),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: (v) =>
              (v ?? '').trim().isEmpty ? s.authErrInvalidEmail : null,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _errorRow(),
        FilledButton.icon(
          onPressed: _nextFromEmail,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(s.authRecoverContinue),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: Navigator.of(context).pop,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(s.authRecoverBack),
        ),
      ],
    );
  }

  Widget _codeStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s, Icons.password, s.authRecoverCodeTitle, s.authRecoverCodeBody),
        // El código GENERADO, a la vista: honestidad sobre el medio offline.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: nexoraSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: nexoraGold.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: [
              Text(
                s.authRecoverCodeWelcome,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: Theme.of(context).disabledColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedCode,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: nexoraGoldLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.authRecoverCodeShown,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (v) => (v ?? '').trim().length != 6 ? s.authRecoverCodeInvalid : null,
          decoration: InputDecoration(
            labelText: s.authRecoverCodeField,
            prefixIcon: const Icon(Icons.pin_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _errorRow(),
        FilledButton.icon(
          onPressed: _verifyCode,
          icon: const Icon(Icons.verified_outlined, size: 18),
          label: Text(s.authRecoverVerify),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _regenerate,
          child: Text(
            s.authRecoverCodeResend,
            style: const TextStyle(color: nexoraGoldLight, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() {
            _step = _RecoveryStep.email;
            _error = null;
          }),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(s.authRecoverBack),
        ),
      ],
    );
  }

  Widget _newPasswordStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s, Icons.key_outlined, s.authRecoverNewTitle, s.authRecoverNewBody),
        TextFormField(
          controller: _newPassword,
          obscureText: true,
          validator: (v) => (v ?? '').length < 6 ? s.authErrWeakPassword : null,
          decoration: InputDecoration(
            labelText: s.authRecoverNewField,
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirm,
          obscureText: true,
          validator: (v) =>
              v != _newPassword.text ? s.authErrMismatch : null,
          decoration: InputDecoration(
            labelText: s.authRecoverNewConfirmField,
            prefixIcon: const Icon(Icons.repeat_rounded),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _errorRow(),
        FilledButton.icon(
          onPressed: _saveNewPassword,
          icon: const Icon(Icons.check, size: 18),
          label: Text(s.authRecoverNewButton),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() {
            _step = _RecoveryStep.code;
            _error = null;
          }),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(s.authRecoverBack),
        ),
      ],
    );
  }

  Widget _doneStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s, Icons.check_circle_outline, s.authRecoverDoneTitle, s.authRecoverDoneBody),
        FilledButton.icon(
          onPressed: _finish,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text(s.authRecoverDoneButton),
        ),
      ],
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