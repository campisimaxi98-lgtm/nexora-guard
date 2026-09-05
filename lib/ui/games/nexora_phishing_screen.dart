/// Phishing Detector — entrenamiento honesto de detección de fraude.
///
/// Los casos se generan LOCALMENTE (nunca llegan correos reales al
/// dispositivo) y el veredicto de cada uno vive en el catálogo puro
/// [phishingCases]: el texto traducido puede cambiar, la verdad no.
library;

import 'package:flutter/material.dart';

import '../../core/games/phishing_cases.dart';
import '../strings.dart';
import '../theme.dart';
import '../components.dart';

class NexoraPhishingScreen extends StatefulWidget {
  const NexoraPhishingScreen({
    super.key,
    required this.strings,
    required this.onBack,
    required this.onFinished,
  });

  final AppStrings strings;
  final VoidCallback onBack;
  final void Function(int score, bool won) onFinished;

  @override
  State<NexoraPhishingScreen> createState() => _NexoraPhishingScreenState();
}

class _NexoraPhishingScreenState extends State<NexoraPhishingScreen> {
  final List<bool?> _answers = [];
  bool _done = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _answers.addAll(List.generate(phishingTotal(), (_) => null));
  }

  int get _index => _answers.indexWhere((a) => a == null);

  int get _correct => _answers.indexed.where((e) {
    return e.$2 != null &&
        e.$2 == phishingIsFraud(phishingCases[e.$1].id);
  }).length;

  void _answer(bool fraudGuess) {
    if (_done) return;
    final i = _answers.indexWhere((a) => a == null);
    setState(() => _answers[i] = fraudGuess);
    if (_answers.every((a) => a != null) && !_reported) {
      _reported = true;
      _done = true;
      widget.onFinished(_correct, _correct == phishingTotal());
    }
  }

  void _restart() {
    setState(() {
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
      _done = false;
      _reported = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ntGap, ntGapSmall, ntGap, 4),
              child: Row(
                children: [
                  IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(
                      s.gmPhishing,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${s.gScore}: $_correct',
                    style: theme.textTheme.bodyMedium?.copyWith(color: nexoraGold),
                  ),
                  const SizedBox(width: ntGapSmall),
                  TextButton(onPressed: _restart, child: Text(s.gNewGame)),
                ],
              ),
            ),
            if (_done)
              _ResultView(
                correct: _correct,
                total: phishingTotal(),
                perfectLabel: s.phPerfect,
                resultLine: s.phResultLine,
                honest: s.phHonest,
                playAgainLabel: s.gNewGame,
                onPlayAgain: _restart,
              )
            else
              _CaseView(
                index: _index,
                sender: widget.strings.phishingCaseLines[_index].$2,
                action: widget.strings.phishingCaseLines[_index].$3,
                counterLabel:
                    '${s.phCaseOf} ${_index + 1} · '
                    '${phishingTotal() - _index - 1} ${s.phRemainingOne}',
                senderLabel: s.phSender,
                actionLabel: s.phAction,
                legitLabel: s.phLegit,
                fraudLabel: s.phFraud,
                onAnswer: _answer,
              ),
          ],
        ),
      ),
    );
  }
}

class _CaseView extends StatelessWidget {
  const _CaseView({
    required this.index,
    required this.sender,
    required this.action,
    required this.counterLabel,
    required this.senderLabel,
    required this.actionLabel,
    required this.legitLabel,
    required this.fraudLabel,
    required this.onAnswer,
  });

  final int index;
  final String sender;
  final String action;
  final String counterLabel;
  final String senderLabel;
  final String actionLabel;
  final String legitLabel;
  final String fraudLabel;
  final void Function(bool fraudGuess) onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ntPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(counterLabel, style: theme.textTheme.bodySmall),
            const SizedBox(height: ntGapSmall),
            NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$senderLabel:  $sender',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ntGapSmall),
                  Text(
                    '$actionLabel:  $action',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: ntGap),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: severityGreen,
                          ),
                          onPressed: () => onAnswer(false),
                          child: Text(legitLabel),
                        ),
                      ),
                      const SizedBox(width: ntGap),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: nexoraRed,
                          ),
                          onPressed: () => onAnswer(true),
                          child: Text(fraudLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: ntGap),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.correct,
    required this.total,
    required this.perfectLabel,
    required this.resultLine,
    required this.honest,
    required this.playAgainLabel,
    required this.onPlayAgain,
  });

  final int correct;
  final int total;
  final String perfectLabel;
  final String resultLine;
  final String honest;
  final String playAgainLabel;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = correct == total;
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(ntPad),
        children: [
          NexoraCard(
            child: Column(
              children: [
                Icon(
                  all ? Icons.verified_rounded : Icons.school_outlined,
                  size: 56,
                  color: all ? severityGreen : nexoraGold,
                ),
                const SizedBox(height: ntGap),
                Text(
                  all ? perfectLabel : '$correct',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: all ? severityGreen : nexoraGold,
                  ),
                ),
                const SizedBox(height: ntGapSmall),
                Text(
                  '$resultLine $correct/$total',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: ntGap),
                FilledButton(onPressed: onPlayAgain, child: Text(playAgainLabel)),
              ],
            ),
          ),
          const SizedBox(height: ntGap),
          Text(
            honest,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}