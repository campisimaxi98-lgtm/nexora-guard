/// Cyber Minesweeper — 100% Flutter puro (sin assets, sin dependencias).
///
/// La lógica del tablero vive en [MinesBoard] (Dart puro, testeable). La
/// pantalla solo pinta celda, contadores, modo destapar/marcar y honestidad
/// al final (no decora con tonterías si perdiste).
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/games/mines_logic.dart';
import '../theme.dart';
import '../components.dart';
import '../strings.dart';

class NexoraMinesScreen extends StatefulWidget {
  const NexoraMinesScreen({
    super.key,
    required this.strings,
    required this.onBack,
    required this.onFinished,
    this.randomSeed,
  });

  final AppStrings strings;
  final VoidCallback onBack;
  final void Function(int score, bool won) onFinished;

  /// Semilla fija para tests deterministas.
  final int? randomSeed;

  @override
  State<NexoraMinesScreen> createState() => _NexoraMinesScreenState();
}

class _NexoraMinesScreenState extends State<NexoraMinesScreen> {
  late MinesBoard _board;
  bool _revealMode = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _newBoard();
  }

  void _newBoard() {
    _board = MinesBoard(
      random: widget.randomSeed != null ? Random(widget.randomSeed) : null,
    );
    _finished = false;
  }

  void _tap(int i) {
    if (_finished) return;
    final action = _revealMode ? _board.reveal(i) : _board.toggleFlag(i);
    if (_finished) return;
    if (action == MinesAction.exploded) {
      setState(() => _finished = true);
      widget.onFinished(_board.revealedCount, false);
    } else if (action == MinesAction.won) {
      setState(() => _finished = true);
      widget.onFinished(_board.revealedCount, true);
    } else {
      setState(() {});
    }
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
            _TopBar(
              title: s.gmMines,
              onBack: widget.onBack,
              score: _board.revealedCount,
              scoreLabel: s.gScore,
              trailing: TextButton(
                onPressed: () => setState(_newBoard),
                child: Text(s.gNewGame),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ntPad),
              child: Row(
                children: [
                  _ModeChip(
                    label: s.minesModeReveal,
                    selected: _revealMode,
                    onTap: () => setState(() => _revealMode = true),
                  ),
                  const SizedBox(width: ntGapSmall),
                  _ModeChip(
                    label: s.minesModeFlag,
                    selected: !_revealMode,
                    onTap: () => setState(() => _revealMode = false),
                  ),
                  const SizedBox(width: ntGapSmall),
                  Expanded(
                    child: Text(
                      '${s.minesRemaining}: '
                      '${_board.minesCount - _board.flagCount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ntGapSmall),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: _board.cols,
                    children: [
                      for (var i = 0; i < _board.rows * _board.cols; i++)
                        _Cell(
                          index: i,
                          board: _board,
                          playing: !_finished,
                          onTap: () => _tap(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ntPad),
              child: _FinishedCard(
                status:
                    _finished
                        ? (_board.exploded
                              ? s.minesExploded
                              : s.minesWon)
                        : null,
                score: _board.revealedCount,
                scoreLabel: s.playScoreUnit,
                playAgainLabel: s.gNewGame,
                onPlayAgain: () => setState(_newBoard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.score,
    required this.scoreLabel,
    required this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final int score;
  final String scoreLabel;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ntGap, vertical: ntGapSmall),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Text(
            '$scoreLabel: $score',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: nexoraGold,
            ),
          ),
          const SizedBox(width: ntGapSmall),
          trailing,
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? nexoraSurfaceRaised
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ntRadiusPill),
          border: Border.all(
            color: selected ? nexoraGold : nexoraBorder,
          ),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.board,
    required this.playing,
    required this.onTap,
  });

  final int index;
  final MinesBoard board;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = board.isRevealed(index);
    final flagged = board.isFlagged(index);
    final mine = board.isMine(index);

    Widget content = const SizedBox.shrink();
    if (revealed && mine && board.exploded) {
      content = const Icon(Icons.brightness_1, size: 18, color: nexoraRed);
    } else if (flagged) {
      content = const Icon(Icons.flag_outlined, size: 18, color: nexoraOrange);
    } else if (revealed) {
      final n = board.adjacentMines(index);
      if (n > 0) {
        content = Text(
          '$n',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: n >= 3 ? nexoraRed : nexoraGoldLight,
            fontWeight: FontWeight.w700,
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: revealed
            ? nexoraSurfaceRaised
            : nexoraSurface,
        borderRadius: BorderRadius.circular(ntRadiusSmall),
        child: InkWell(
          key: ValueKey('mines-cell-$index'),
          onTap: playing && !revealed ? onTap : null,
          borderRadius: BorderRadius.circular(ntRadiusSmall),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({
    required this.status,
    required this.score,
    required this.scoreLabel,
    required this.playAgainLabel,
    required this.onPlayAgain,
  });

  final String? status;
  final int score;
  final String scoreLabel;
  final String playAgainLabel;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    return NexoraCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$status  $scoreLabel: $score',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          FilledButton(onPressed: onPlayAgain, child: Text(playAgainLabel)),
        ],
      ),
    );
  }
}