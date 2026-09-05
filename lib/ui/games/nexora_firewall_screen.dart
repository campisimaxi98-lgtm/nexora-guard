/// Firewall — minijuego de bloqueo de paquetes, 100% Flutter puro.
///
/// Sin assets: la retícula y las amenazas las pinta un [CustomPainter]. El
/// jugador toca un carril para bloquear el paquete hostil más cercano al
/// núcleo. La dificultad crece por ola (más paquetes, más rápidos) — todo
/// con valores reales, sin simulación mágica.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../components.dart';

class NexoraFirewallScreen extends StatefulWidget {
  const NexoraFirewallScreen({
    super.key,
    required this.strings,
    required this.onBack,
    required this.onFinished,
    this.randomSeed,
  });

  final AppStrings strings;
  final VoidCallback onBack;
  final void Function(int score, bool won) onFinished;

  /// Semilla fija para la aparición de paquetes en tests.
  final int? randomSeed;

  @override
  State<NexoraFirewallScreen> createState() => _NexoraFirewallScreenState();
}

class _Threat {
  _Threat(this.column, this.progress);
  final int column;
  double progress;
}

class _NexoraFirewallScreenState extends State<NexoraFirewallScreen> {
  static const int _columns = 5;
  static const int _maxLives = 5;
  static const int _winScore = 50;

  late Random _random;
  Timer? _timer;
  final List<_Threat> _threats = [];
  bool _over = false;
  bool _won = false;
  int _score = 0;
  int _lives = _maxLives;
  int _tickCount = 0;

  int get _wave => 1 + _score ~/ 10;

  @override
  void initState() {
    super.initState();
    _random = Random(widget.randomSeed);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _threats.clear();
    _over = false;
    _won = false;
    _score = 0;
    _lives = _maxLives;
    _tickCount = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) => _tick());
  }

  void _tick() {
    if (_over || !mounted) return;
    setState(() {
      _tickCount++;
      final speed = 0.09 + _wave * 0.01;
      final remaining = <_Threat>[];
      for (final t in _threats) {
        t.progress += speed;
        if (t.progress < 1.0) {
          remaining.add(t);
        } else {
          _lives--;
        }
      }
      _threats
        ..clear()
        ..addAll(remaining);

      // Aparición: más probable y más densa con cada ola.
      if (_random.nextDouble() < min(0.32 + _wave * 0.03, 0.7) &&
          _threats.length < _columns * 3) {
        _threats.add(_Threat(_random.nextInt(_columns), 0.0));
      }

      if (_lives <= 0) {
        _over = true;
        _won = false;
        _finish();
      } else if (_score >= _winScore && !_won) {
        _over = true;
        _won = true;
        widget.onFinished(_score, true);
      }
    });
  }

  void _blockColumn(int column) {
    if (_over) return;
    setState(() {
      final nearest = _threats
          .where((t) => t.column == column)
          .fold<_Threat?>(
            null,
            (best, t) =>
                best == null || t.progress > best.progress ? t : best,
          );
      if (nearest != null) {
        _threats.remove(nearest);
        _score++;
        if (_score >= _winScore) {
          _over = true;
          _won = true;
        }
      }
    });
    if (mounted && _over && _won) widget.onFinished(_score, true);
  }

  void _finish() {
    widget.onFinished(_score, false);
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
                      s.gmFirewall,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${s.gScore}: $_score',
                    style: theme.textTheme.bodyMedium?.copyWith(color: nexoraGold),
                  ),
                  const SizedBox(width: ntGapSmall),
                  TextButton(
                    onPressed: () => setState(_start),
                    child: Text(s.gNewGame),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ntPad),
              child: Row(
                children: [
                  Text('${s.fwLives}: $_lives'),
                  const SizedBox(width: ntGap),
                  Text('${s.fwWave}: $_wave'),
                  const Spacer(),
                  Text('${s.fwBlcked}: $_score'),
                ],
              ),
            ),
            const SizedBox(height: ntGapSmall),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final width = MediaQuery.of(context).size.width - 2 * ntPad;
                  final lane = (details.localPosition.dx / (width / _columns))
                      .floor()
                      .clamp(0, _columns - 1);
                  _blockColumn(lane);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ntPad),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _FirewallPainter(
                      threats: _threats,
                      columns: _columns,
                      lives: _lives,
                      score: _score,
                      over: _over,
                      won: _won,
                      tickCount: _tickCount,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ntPad),
              child: _FirewallFooter(
                hint: s.fwHint,
                status: _over ? (_won ? s.gWin : s.fwGameOver) : null,
                score: _score,
                scoreUnit: s.playScoreUnit,
                playAgainLabel: s.gNewGame,
                onPlayAgain: () => setState(_start),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirewallPainter extends CustomPainter {
  _FirewallPainter({
    required this.threats,
    required this.columns,
    required this.lives,
    required this.score,
    required this.over,
    required this.won,
    required this.tickCount,
  });

  final List<_Threat> threats;
  final int columns;
  final int lives;
  final int score;
  final bool over;
  final bool won;
  final int tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final laneW = size.width / columns;
    const padY = 8.0;

    // Núcleo (línea inferior).
    final coreY = size.height - 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, coreY, size.width - 8, 10),
        const Radius.circular(4),
      ),
      Paint()..color = won ? severityGreen : nexoraWine,
    );

    // Carriles.
    final lanePaint = Paint()
      ..color = nexoraBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var c = 1; c < columns; c++) {
      canvas.drawLine(
        Offset(laneW * c, padY),
        Offset(laneW * c, coreY - 4),
        lanePaint,
      );
    }

    // Paquetes hostiles.
    for (final t in threats) {
      final dx = laneW * (t.column + 0.5);
      final dy = coreY - 6 - t.progress * (coreY - 8 - padY);
      canvas.drawCircle(
        Offset(dx, dy),
        7,
        Paint()..color = nexoraRed.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(dx, dy),
        3.2,
        Paint()..color = nexoraOrange,
      );
    }

    if (over) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = nexoraBackground.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirewallPainter old) =>
      old.tickCount != tickCount ||
      old.score != score ||
      old.lives != lives ||
      old.over != over ||
      old.won != won;
}

class _FirewallFooter extends StatelessWidget {
  const _FirewallFooter({
    required this.hint,
    required this.status,
    required this.score,
    required this.scoreUnit,
    required this.playAgainLabel,
    required this.onPlayAgain,
  });

  final String hint;
  final String? status;
  final int score;
  final String scoreUnit;
  final String playAgainLabel;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Text(
        hint,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color:
              Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      );
    }
    return NexoraCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$status   ($scoreUnit: $score)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          FilledButton(onPressed: onPlayAgain, child: Text(playAgainLabel)),
        ],
      ),
    );
  }
}