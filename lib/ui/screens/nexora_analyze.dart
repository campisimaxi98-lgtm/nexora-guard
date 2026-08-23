/// Analizar mensaje — la persona pega un SMS, WhatsApp o mail sospechoso
/// y lo manda al backend (precheck + ChatGPT + Claude + VirusTotal +
/// NEXORA BRAIN). Es la forma real de cubrir WhatsApp/mail: la app no
/// puede leer esas bandejas automáticamente (ver docs/connected-flavor.md
/// y las notas de la conversación sobre restricciones de plataforma),
/// pero sí puede analizar bajo demanda cualquier texto que le pases.
library;

import 'package:flutter/material.dart';

import '../../core/nexora_api_client.dart';
import '../theme.dart';

class NexoraAnalyzeScreen extends StatefulWidget {
  const NexoraAnalyzeScreen({
    super.key,
    required this.serverUrl,
    required this.token,
  });

  final String serverUrl;
  final String token;

  @override
  State<NexoraAnalyzeScreen> createState() => _NexoraAnalyzeScreenState();
}

class _NexoraAnalyzeScreenState extends State<NexoraAnalyzeScreen> {
  final _textController = TextEditingController();
  final _phoneController = TextEditingController();
  String _channel = 'sms';
  bool _loading = false;
  NexoraAnalysisResult? _result;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    final client = NexoraApiClient(
      baseUrl: widget.serverUrl,
      token: widget.token,
    );
    try {
      final result = await client.analyzeText(
        text,
        channel: _channel,
        alertPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      setState(() => _result = result);
    } on NexoraApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: nexoraBackground,
    appBar: AppBar(
      backgroundColor: nexoraBackground,
      title: const Text('Analizar mensaje'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'Pegá acá el SMS, WhatsApp o mail sospechoso. NEXORA lo analiza '
            'con las mismas cuatro fuentes que usa para SMS reales.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final c in const [
                ('sms', 'SMS'),
                ('whatsapp', 'WhatsApp'),
                ('email', 'Mail'),
                ('other', 'Otro'),
              ])
                ChoiceChip(
                  label: Text(c.$2),
                  selected: _channel == c.$1,
                  onSelected: (_) => setState(() => _channel = c.$1),
                  selectedColor: nexoraGold,
                  backgroundColor: nexoraSurface,
                  labelStyle: TextStyle(
                    color: _channel == c.$1 ? nexoraBackground : Colors.white70,
                    fontSize: 12,
                  ),
                  side: const BorderSide(color: nexoraBorder),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textController,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pegá el mensaje completo acá…',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: nexoraSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'Opcional: tu número para recibir SMS de alerta si es peligroso',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12.5),
              filled: true,
              fillColor: nexoraSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nexoraGold,
                foregroundColor: nexoraBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loading ? null : _analyze,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: nexoraBackground,
                      ),
                    )
                  : const Text(
                      'ANALIZAR',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _error != null
                ? _ErrorCard(key: const ValueKey('err'), message: _error!)
                : _result != null
                ? _ResultCard(key: const ValueKey('res'), result: _result!)
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: nexoraWine,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: Colors.white)),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result});
  final NexoraAnalysisResult result;

  Color get _color => switch (result.riskLevel) {
    'HIGH' => nexoraRed,
    'MEDIUM' => const Color(0xFFF5AB3D),
    _ => const Color(0xFF37D69C),
  };

  String get _label => switch (result.riskLevel) {
    'HIGH' => 'RIESGO ALTO',
    'MEDIUM' => 'PRECAUCIÓN',
    _ => 'RIESGO BAJO',
  };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _color.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.riskLevel == 'HIGH' ? Icons.gpp_bad : Icons.gpp_maybe,
              color: _color,
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${result.riskScore}/100',
              style: TextStyle(color: _color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (result.uncertain) ...[
          const SizedBox(height: 8),
          const Text(
            'Las fuentes no coinciden del todo — confianza reducida en este resultado.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
        if (result.signals.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in result.signals)
                Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  backgroundColor: nexoraSurfaceRaised,
                  labelStyle: const TextStyle(color: Colors.white70),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Text(
          result.alertSent
              ? '📩 Se envió un SMS de alerta al número indicado.'
              : 'Fuentes usadas: ${result.sourcesUsed.join(', ')}',
          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
        ),
      ],
    ),
  );
}
