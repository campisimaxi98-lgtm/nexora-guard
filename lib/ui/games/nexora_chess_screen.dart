/// Cyber Chess — ajedrez didáctico, 100% Flutter puro.
///
/// El motor vive en [ChessEngine] (Dart puro, testeable). Aquí solo se pinta
/// el tablero, se capturan los toques y se anima: el rival elige una movida
/// LEGAL al azar y la UI lo dice honestamente en la nota.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/games/chess_engine.dart';
import '../strings.dart';
import '../theme.dart';
import '../components.dart';

class NexoraChessScreen extends StatefulWidget {
  const NexoraChessScreen({
    super.key,
    required this.strings,
    required this.onBack,
    required this.onFinished,
    this.randomSeed,
  });

  final AppStrings strings;
  final VoidCallback onBack;
  final void Function(int score, bool won) onFinished;

  /// Semilla fija para el rival en tests deterministas.
  final int? randomSeed;

  @override
  State<NexoraChessScreen> createState() => _NexoraChessScreenState();
}

class _NexoraChessScreenState extends State<NexoraChessScreen> {
  late Board _board;
  late Random _random;
  int? _selected;
  Set<int> _hints = const {};
  final List<Piece> _whiteCaptures = [];
  final List<Piece> _blackCaptures = [];
  bool _ended = false;
  bool _checkWhite = false;
  bool _checkBlack = false;
  String? _resultKey; // 'checkmate'|'stalemate'
  bool? _winner; // true = blancas (jugador)

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _board = Board.initial();
    _random = Random(widget.randomSeed);
    _selected = null;
    _hints = const {};
    _whiteCaptures.clear();
    _blackCaptures.clear();
    _ended = false;
    _checkWhite = false;
    _checkBlack = false;
    _resultKey = null;
    _winner = null;
  }

  String get _scoreLabel => '${_materialPoints(_whiteCaptures) * 10}';

  void _tapSquare(int i) {
    if (_ended) return;
    final piece = _board.atIdx(i);

    // Mover a destino válido de la pieza seleccionada.
    if (_selected != null && _hints.contains(i)) {
      _applyPlayerMove(_selected!, i);
      return;
    }
    // Seleccionar pieza blanca del jugador.
    if (piece != null && piece.white) {
      setState(() {
        _selected = i;
        _hints = {...ChessEngine.legalMoves(_board, i).map((m) => m.$2)};
      });
      return;
    }
    // Tocar otro → deseleccionar.
    setState(() {
      _selected = null;
      _hints = const {};
    });
  }

  void _applyPlayerMove(int from, int to) {
    final captured = _board.atIdx(to);
    setState(() {
      _board = ChessEngine.move(_board, from, to);
      _selected = null;
      _hints = const {};
      if (captured != null && captured.kind != 'k') _whiteCaptures.add(captured);
    });
    _afterMove();
  }

  void _afterMove() {
    final state = ChessEngine.gameState(_board);
    if (state == 'checkmate' || state == 'stalemate') {
      setState(() {
        _ended = true;
        _resultKey = state;
        _checkWhite = state == 'checkmate' && ChessEngine.inCheck(_board, true);
        _checkBlack = state == 'checkmate' && ChessEngine.inCheck(_board, false);
        _winner = _checkBlack;
      });
      final score = _materialPoints(_whiteCaptures) * 10 +
          (_winner == true ? 100 : 0) +
          (state == 'stalemate' ? 20 : 0);
      widget.onFinished(score, _winner == true || state == 'stalemate');
      return;
    }

    _checkBlack = ChessEngine.inCheck(_board, false);
    // Turno del rival (negras): movida legal al azar, honesta.
    final aiMove = ChessEngine.randomMove(_board, false, _random);
    if (aiMove == null) return;
    final captured = _board.atIdx(aiMove.$2);
    setState(() {
      _board = ChessEngine.move(_board, aiMove.$1, aiMove.$2);
      if (captured != null && captured.kind != 'k') _blackCaptures.add(captured);
    });
    final after = ChessEngine.gameState(_board);
    if (after == 'checkmate' || after == 'stalemate') {
      setState(() {
        _ended = true;
        _resultKey = after;
        _checkWhite = after == 'checkmate' && ChessEngine.inCheck(_board, true);
        _checkBlack = after == 'checkmate' && ChessEngine.inCheck(_board, false);
        _winner = _checkBlack;
      });
      final score = _materialPoints(_whiteCaptures) * 10 +
          (_winner == true ? 100 : 0) +
          (after == 'stalemate' ? 20 : 0);
      widget.onFinished(score, _winner == true || after == 'stalemate');
      return;
    }
    setState(() => _checkWhite = ChessEngine.inCheck(_board, true));
  }

  static int _materialPoints(List<Piece> captures) =>
      captures.fold(0, (sum, p) => sum + p.value);

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
                      s.gmChess,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${s.gScore}: $_scoreLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(color: nexoraGold),
                  ),
                  const SizedBox(width: ntGapSmall),
                  TextButton(
                    onPressed: () => setState(_newGame),
                    child: Text(s.gNewGame),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ntPad),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _ended
                          ? _resultText(s)
                          : (_checkWhite
                                ? '${s.chessTurnWhite} · ${s.chessCheck}'
                                : s.chessTurnWhite),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    s.chessYouWhite,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
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
                    crossAxisCount: 8,
                    children: [
                      for (var i = 0; i < 64; i++)
                        _Square(
                          index: i,
                          board: _board,
                          selected: _selected == i,
                          hinted: _hints.contains(i),
                          check: (_checkWhite && ChessEngine.findKing(
                            _board,
                            true,
                          ) == i) ||
                              (_checkBlack &&
                                  ChessEngine.findKing(_board, false) == i),
                          onTap: () => _tapSquare(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ntPad),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${s.chessYourCaptures}: ${_capturedTokens(_whiteCaptures)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${s.chessRivalCaptures}: ${_capturedTokens(_blackCaptures)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ntPad),
              child: _ChessFooter(
                honest: s.chessHonest,
                status: _ended ? _resultText(s) : null,
                playAgainLabel: s.gNewGame,
                onPlayAgain: () => setState(_newGame),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resultText(AppStrings s) {
    if (_resultKey == null) return '';
    if (_resultKey == 'stalemate') return s.chessStalemate;
    if (_winner == true) return '${s.chessCheckmate} · ${s.chessYouWin}';
    return '${s.chessCheckmate} · ${s.chessYouLose}';
  }

  static String _capturedTokens(List<Piece> captures) =>
      captures.map((p) => _glyph(p)).join(' ');
}

String _glyph(Piece p) {
  const whiteGlyphs = {'k': '♔', 'q': '♕', 'r': '♖', 'b': '♗', 'n': '♘', 'p': '♙'};
  const blackGlyphs = {'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟'};
  return p.white ? whiteGlyphs[p.kind]! : blackGlyphs[p.kind]!;
}

class _Square extends StatelessWidget {
  const _Square({
    required this.index,
    required this.board,
    required this.selected,
    required this.hinted,
    required this.check,
    required this.onTap,
  });

  final int index;
  final Board board;
  final bool selected;
  final bool hinted;
  final bool check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = (index ~/ 8 + index % 8) % 2 == 1;
    Color base = dark ? nexoraBorder : nexoraSurfaceRaised;
    if (selected) base = nexoraGold.withValues(alpha: 0.45);
    const piece = nexoraGoldLight;
    final pieceGlyph = _glyphFor(board.atIdx(index));
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: base,
        borderRadius: BorderRadius.circular(ntRadiusSmall - 4),
        child: InkWell(
          key: ValueKey('chess-square-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(ntRadiusSmall - 4),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hinted)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: piece.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (pieceGlyph != null)
                  Text(
                    pieceGlyph,
                    style: TextStyle(
                      fontSize: 26,
                      color: check ? nexoraRed : piece,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _glyphFor(Piece? p) => p == null ? null : _glyph(p);
}

class _ChessFooter extends StatelessWidget {
  const _ChessFooter({
    required this.honest,
    required this.status,
    required this.playAgainLabel,
    required this.onPlayAgain,
  });

  final String honest;
  final String? status;
  final String playAgainLabel;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Text(
        honest,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(
            alpha: 0.7,
          ),
        ),
      );
    }
    return NexoraCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$status\n$honest',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          FilledButton(onPressed: onPlayAgain, child: Text(playAgainLabel)),
        ],
      ),
    );
  }
}