/// Nexora — asistente de preguntas frecuentes sobre seguridad digital.
///
/// Nota honesta: esto NO es un modelo de IA conectado a un servidor (la app
/// no tiene backend ni hace requests de red — ver `check-no-internet.sh` en
/// `scripts/`). Es un asistente local de reglas: reconoce palabras clave y
/// devuelve contenido educativo pre-escrito. Si el mensaje no matchea
/// ninguna regla, ofrece las mismas preguntas rápidas como alternativa.
library;

import 'package:flutter/material.dart';

import '../nexora_logo.dart';
import '../theme.dart';

class _BotMessage {
  const _BotMessage(this.text, this.fromBot);
  final String text;
  final bool fromBot;
}

const _quickReplies = [
  '¿Cómo funciona la protección?',
  '¿Qué es el phishing?',
  'Revisar mi dispositivo',
  'Reportar un problema',
];

String _answerFor(String question) {
  final q = question.toLowerCase();
  if (q.contains('phishing')) {
    return 'El phishing es un tipo de engaño donde alguien se hace pasar '
        'por una entidad confiable (tu banco, una app, un contacto) para '
        'que compartas contraseñas, códigos o datos de tarjetas. '
        'Desconfiá de mensajes urgentes que piden datos sensibles o que '
        'te llevan a un enlace para "verificar" tu cuenta.';
  }
  if (q.contains('funciona') || q.contains('protección')) {
    return 'NEXORA analiza el dispositivo en busca de apps con permisos '
        'riesgosos, cambios anómalos de red/almacenamiento y patrones '
        'conocidos de amenaza. Todo el análisis ocurre en tu propio '
        'teléfono — no se envían tus datos a ningún servidor.';
  }
  if (q.contains('revisar') || q.contains('dispositivo') || q.contains('escan')) {
    return 'Para revisar tu dispositivo ahora mismo, andá a la pestaña '
        '"Análisis" y tocá "Iniciar análisis". Te va a mostrar el estado '
        'de apps, red y almacenamiento en tiempo real.';
  }
  if (q.contains('reportar') || q.contains('problema')) {
    return 'Si encontraste algo sospechoso, andá a "Perfil → Acerca de" '
        'y usá la opción para compartir el registro de diagnóstico. '
        'Queda guardado localmente y podés compartirlo vos mismo, nunca '
        'se envía automáticamente.';
  }
  if (q.contains('hola') || q.contains('buenas')) {
    return '¡Hola! Preguntame sobre phishing, cómo funciona la protección, '
        'o pedime que te ayude a revisar el dispositivo.';
  }
  return 'Por ahora puedo ayudarte con preguntas sobre phishing, cómo '
      'funciona la protección de NEXORA, o guiarte para revisar tu '
      'dispositivo. Probá una de las preguntas rápidas de abajo.';
}

class NexoraBotScreen extends StatefulWidget {
  const NexoraBotScreen({super.key});

  @override
  State<NexoraBotScreen> createState() => _NexoraBotScreenState();
}

class _NexoraBotScreenState extends State<NexoraBotScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_BotMessage> _messages = [
    const _BotMessage(
      '¡Hola! Soy Nexora 🤖\nEstoy acá para ayudarte con seguridad '
      'digital. Esto es un asistente local con respuestas predefinidas, '
      'no una IA conectada a internet.',
      true,
    ),
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_BotMessage(text.trim(), false));
      _messages.add(_BotMessage(_answerFor(text), true));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    appBar: AppBar(
      backgroundColor: nexoraBackground,
      title: Row(
        children: [
          const NexoraLogo(size: 30, showRing: false),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Nexora',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              Text(
                'Asistente local · sin conexión',
                style: TextStyle(fontSize: 10.5, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _Bubble(message: _messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in _quickReplies)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: nexoraGoldLight,
                      side: const BorderSide(color: nexoraBorder),
                      backgroundColor: nexoraSurface,
                    ),
                    onPressed: () => _send(q),
                    child: Text(q, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje…',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: nexoraSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: nexoraWine,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _send(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _BotMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromBot ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: message.fromBot ? nexoraSurfaceRaised : nexoraGold,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.fromBot ? Colors.white : nexoraBackground,
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
    ),
  );
}
