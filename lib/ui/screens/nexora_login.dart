/// Login / crear cuenta — SOLO existe (y solo tiene sentido) en el flavor
/// `connected`, porque necesita el backend NEXORA GUARD para validar
/// credenciales. El flavor `offline` nunca muestra esta pantalla.
///
/// Nota honesta: el token de sesión se guarda en el mismo archivo JSON
/// local de configuración que el resto de los ajustes de la app — no es
/// un almacén cifrado por hardware (como Keystore/Keychain). Para un uso
/// personal está bien; si esto se publica para terceros, migrar el token
/// a almacenamiento seguro nativo es un paso pendiente, no algo ya hecho.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/nexora_api_client.dart';
import '../nexora_logo.dart';
import '../theme.dart';

class NexoraLoginScreen extends StatefulWidget {
  const NexoraLoginScreen({
    super.key,
    required this.serverUrl,
    required this.onAuthenticated,
    required this.onNeedServerUrl,
    this.initialRegister = false,
  });

  final String serverUrl;

  /// Se llama con (token, email) cuando el login/registro funciona.
  final void Function(String token, String email) onAuthenticated;

  /// Se llama si todavía no hay URL de servidor configurada.
  final VoidCallback onNeedServerUrl;

  /// Arranca directo en el formulario de "crear cuenta" (viene de tocar
  /// ese botón en el splash). Si es false, arranca en "iniciar sesión".
  final bool initialRegister;

  @override
  State<NexoraLoginScreen> createState() => _NexoraLoginScreenState();
}

class _NexoraLoginScreenState extends State<NexoraLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late bool _isRegister = widget.initialRegister;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _logoController,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.serverUrl.trim().isEmpty) {
      widget.onNeedServerUrl();
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final client = NexoraApiClient(baseUrl: widget.serverUrl.trim());
    try {
      final result = _isRegister
          ? await client.register(
              _emailController.text.trim(),
              _passwordController.text,
            )
          : await client.login(
              _emailController.text.trim(),
              _passwordController.text,
            );
      // Confirma el autofill: esto es lo que le indica a Android/iOS que
      // las credenciales que se acaban de tipear funcionaron, y dispara el
      // cartel nativo de "¿Guardar contraseña?" del propio teléfono. Sin
      // esta llamada, el sistema nunca sabe si el intento fue exitoso.
      TextInput.finishAutofillContext();
      widget.onAuthenticated(result.token, result.email);
    } on NexoraApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: const NexoraLogo(size: 96),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isRegister ? 'Creá tu cuenta' : 'Bienvenido de nuevo',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat en línea y estadísticas de NEXORA',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _error == null
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(_error),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: nexoraWine.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Email', Icons.mail_outline),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(value)) {
                        return 'Ingresá un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: [
                      _isRegister
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _fieldDecoration(
                          'Contraseña',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white38,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                    validator: (v) =>
                        (v?.length ?? 0) < 8 ? 'Mínimo 8 caracteres' : null,
                  ),
                  const SizedBox(height: 22),
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
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: nexoraBackground,
                              ),
                            )
                          : Text(
                              _isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? '¿Ya tenés cuenta? Iniciar sesión'
                          : '¿No tenés cuenta? Crear una',
                      style: const TextStyle(
                        color: nexoraGoldLight,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: nexoraSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: nexoraBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: nexoraGold, width: 1.4),
        ),
      );
}
