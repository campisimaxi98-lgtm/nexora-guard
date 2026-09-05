/// Nexora AI — chat local contextual (FASE 9).
///
/// Conecta la pantalla al [NexoraAIEngine]: respuestas basadas en datos
/// REALES del snapshot y del veredicto (batería, temperatura, memoria,
/// almacenamiento, nivel por app, alertas). Sigue siendo 100% local y sin
/// red; cuando el motor no tiene el dato lo dice con honestidad.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../nexora_ai.dart';
import '../nexora_logo.dart';
import '../strings.dart';
import '../theme.dart';

class _BotMessage {
  const _BotMessage(this.text, this.fromBot);
  final String text;
  final bool fromBot;
}

class NexoraBotScreen extends StatefulWidget {
  const NexoraBotScreen({
    super.key,
    required this.strings,
    this.snapshot,
    this.verdict,
  });

  final AppStrings strings;
  final Snapshot? snapshot;
  final Verdict? verdict;

  @override
  State<NexoraBotScreen> createState() => _NexoraBotScreenState();
}

class _NexoraBotScreenState extends State<NexoraBotScreen> {
  late final NexoraAIEngine _engine;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_BotMessage> _messages = [];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _engine = NexoraAIEngine(
      strings: widget.strings,
      snapshot: widget.snapshot,
      verdict: widget.verdict,
    );
    _messages.add(_BotMessage(widget.strings.aiGreeting, true));
    final note = widget.strings.aiHonestNote;
    if (note.isNotEmpty) {
      _messages.add(_BotMessage('$note\n\n${widget.strings.aiIntro}', true));
    } else {
      _messages.add(_BotMessage(widget.strings.aiIntro, true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _thinking) return;
    setState(() {
      _messages.add(_BotMessage(trimmed, false));
      _thinking = true;
    });
    _controller.clear();
    _scrollDown();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() {
      _messages.add(_BotMessage(_engine.answer(trimmed), true));
      _thinking = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    appBar: AppBar(
      backgroundColor: nexoraSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          const NexoraLogo(size: 30, showRing: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.strings.aiTitle,
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  widget.strings.aiHonestNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
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
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (_thinking && i == _messages.length) {
                  return const _ThinkingBubble();
                }
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          if (_engine.quickPrompts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in _engine.quickPrompts)
                    ActionChip(
                      onPressed: _thinking ? null : () => _send(q),
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      backgroundColor: nexoraSurfaceRaised,
                      side: const BorderSide(color: nexoraBorder),
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
                      hintText: widget.strings.aiTypeMessage,
                      hintStyle: TextStyle(
                        color: Theme.of(context).disabledColor,
                      ),
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
                  backgroundColor: nexoraGold,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: nexoraBackground,
                      size: 18,
                    ),
                    onPressed: _thinking ? null : () => _send(_controller.text),
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
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 300),
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

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: nexoraSurfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: nexoraGold),
          ),
          SizedBox(width: 10),
          Text('…', style: TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}