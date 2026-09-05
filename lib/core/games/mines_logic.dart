/// Núcleo de Cyber Minesweeper — Dart puro, sin Flutter.
///
/// Generación honesta: tras el primer destapado se colocan las minas lejos
/// de la celda inicial (el clásico "primera casilla siempre segura"). Toda la
/// lógica de minado, números y victoria vive aquí para poder testearla sin
/// interacción.
library;

import 'dart:math';

enum MinesAction {
  revealed,
  flagged,
  unflagged,
  exploded,
  won,
  noop,
}

class MinesBoard {
  MinesBoard({
    this.rows = 8,
    this.cols = 8,
    this.mines = 10,
    Random? random,
  }) : _random = random ?? Random();

  final int rows;
  final int cols;
  final int mines;
  final Random _random;

  late final int _totalCells = rows * cols;
  final Set<int> _minesSet = {};
  final Set<int> _revealed = {};
  final Set<int> _flags = {};
  bool _started = false;
  bool _exploded = false;
  bool _won = false;
  int _revealCount = 0;

  bool get started => _started;
  bool get exploded => _exploded;
  bool get won => _won;

  int get safeCells => _totalCells - mines;
  int get revealedCount => _revealCount;
  int get minesCount => mines;
  int get flagCount => _flags.length;

  bool isMine(int i) => _minesSet.contains(i);
  bool isRevealed(int i) => _revealed.contains(i);
  bool isFlagged(int i) => _flags.contains(i);

  static bool inBounds(int i, int rows, int cols) =>
      i >= 0 && i < rows * cols;

  List<int> neighbors(int i) {
    final r = i ~/ cols, c = i % cols;
    final out = <int>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        out.add(nr * cols + nc);
      }
    }
    return out;
  }

  int adjacentMines(int i) =>
      neighbors(i).where(isMine).length;

  void _seed(int first) {
    final forbidden = {first, ...neighbors(first)};
    final candidates = [
      for (var i = 0; i < _totalCells; i++)
        if (!forbidden.contains(i)) i,
    ]..shuffle(_random);
    _minesSet.addAll(candidates.take(mines));
    _started = true;
  }

  /// Descubre una casilla. El primer toque nunca es mina.
  MinesAction reveal(int i) {
    if (_exploded || _won) return MinesAction.noop;
    if (_revealed.contains(i) || _flags.contains(i)) return MinesAction.noop;
    if (!_started) _seed(i);

    if (_minesSet.contains(i)) {
      _revealed.add(i);
      _exploded = true;
      return MinesAction.exploded;
    }

    _floodReveal(i);
    if (_revealed.length == safeCells) {
      _won = true;
      return MinesAction.won;
    }
    return MinesAction.revealed;
  }

  void _floodReveal(int i) {
    final stack = [i];
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      if (_revealed.contains(cell) || _flags.contains(cell)) continue;
      _revealed.add(cell);
      _revealCount++;
      if (adjacentMines(cell) == 0) {
        for (final n in neighbors(cell)) {
          if (!_revealed.contains(n) && !isMine(n) && !_flags.contains(n)) {
            stack.add(n);
          }
        }
      }
    }
  }

  MinesAction toggleFlag(int i) {
    if (_exploded || _won || _revealed.contains(i)) return MinesAction.noop;
    if (_flags.contains(i)) {
      _flags.remove(i);
      return MinesAction.unflagged;
    }
    if (_flags.length >= mines) return MinesAction.noop;
    _flags.add(i);
    return MinesAction.flagged;
  }
}