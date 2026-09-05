/// Motor de ajedrez — Dart puro, sin Flutter y sin dependencias.
///
/// Variante didáctica honesta: reglas clásicas SIMPLIFICADAS (sin enroque,
/// sin en passant, la promoción es automática a dama). La etiqueta de la UI
/// lo dice; este motor no finge ser un ajedrez completo.
library;

import 'dart:math';

class Piece {
  Piece(this.white, String kind) : kind = kind.toLowerCase();

  final bool white;
  final String kind; // 'p','r','n','b','q','k' (siempre minúscula)

  static const charRanks = 'prnbqk';

  /// 'P'…'K' si es blanca, 'p'…'k' si es negra.
  String get token => white ? kind.toUpperCase() : kind;

  int get value {
    switch (kind) {
      case 'p':
        return 1;
      case 'n':
      case 'b':
        return 3;
      case 'r':
        return 5;
      case 'q':
        return 9;
      default:
        return 0;
    }
  }
}

class Board {
  /// 64 celdas; `null` = vacío. Indice 0 = a8 (fila 0, negras arriba).
  final List<Piece?> cells;

  const Board(this.cells);

  factory Board.initial() => Board([
    ..._rank('rnbqkbnr', white: false),
    ..._rank('pppppppp', white: false),
    ...List.filled(32, null),
    ..._rank('PPPPPPPP', white: true),
    ..._rank('RNBQKBNR', white: true),
  ]);

  static List<Piece?> _rank(String coded, {required bool white}) =>
      [for (final c in coded.split('')) Piece(white, c)];

  static int index(int file, int rank) => rank * 8 + file;

  Piece? at(int file, int rank) => cells[index(file, rank)];

  Piece? atIdx(int i) => i >= 0 && i < 64 ? cells[i] : null;

  static bool isWhite(Piece? p) => p != null && p.white;

  static String label(int i) => '${'abcdefgh'[i % 8]}${8 - i ~/ 8}';

  /// Row de la fila 0..7 como lista de tokens (para export/pintar).
  List<String?> row(int rank) =>
      [for (var f = 0; f < 8; f++) cells[rank * 8 + f]?.token];
}

/// Direcciones de ataque por pieza (desplazamientos [df, dr]).
const _knightDirs = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]];
const _bishopDirs = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
const _rookDirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];

class ChessEngine {
  ChessEngine._();

  /// Todos los destinos legales (índices) de la pieza en `from`, SIN
  /// comprobar jaque (el filtro de jaque viene aparte).
  static List<int> pseudoMoves(Board b, int from) {
    final piece = b.atIdx(from);
    if (piece == null) return const [];
    final f = from % 8, r = from ~/ 8;
    final out = <int>[];
    void slide(List<List<int>> dirs) {
      for (final d in dirs) {
        var nf = f + d[0], nr = r + d[1];
        while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
          final target = b.at(nf, nr);
          if (target == null) {
            out.add(Board.index(nf, nr));
          } else {
            if (target.white != piece.white) out.add(Board.index(nf, nr));
            break;
          }
          nf += d[0];
          nr += d[1];
        }
      }
    }

    switch (piece.kind) {
      case 'r':
        slide(_rookDirs);
      case 'b':
        slide(_bishopDirs);
      case 'q':
        slide([..._rookDirs, ..._bishopDirs]);
      case 'k':
        for (final d in [..._rookDirs, ..._bishopDirs]) {
          final nf = f + d[0], nr = r + d[1];
          if (nf < 0 || nf > 7 || nr < 0 || nr > 7) continue;
          final target = b.at(nf, nr);
          if (target == null) out.add(Board.index(nf, nr));
          if (target != null && target.white != piece.white) {
            out.add(Board.index(nf, nr));
          }
        }
      case 'n':
        for (final d in _knightDirs) {
          final nf = f + d[0], nr = r + d[1];
          if (nf < 0 || nf > 7 || nr < 0 || nr > 7) continue;
          final target = b.at(nf, nr);
          if (target == null) out.add(Board.index(nf, nr));
          if (target != null && target.white != piece.white) {
            out.add(Board.index(nf, nr));
          }
        }
      case 'p':
        // Fila 0 = a8 (negras), fila 7 = a1 (blancas): las blancas avanzan
        // hacia la fila 0 y las negras hacia la fila 7.
        final dir = piece.white ? -1 : 1;
        final startRank = piece.white ? 6 : 1;
        final one = Board.index(f, r + dir);
        if (r + dir >= 0 && r + dir < 8 && b.atIdx(one) == null) {
          out.add(one);
          if (r == startRank) {
            final two = Board.index(f, r + 2 * dir);
            if (b.atIdx(two) == null) out.add(two);
          }
        }
        for (final df in [-1, 1]) {
          final nf = f + df, nr = r + dir;
          if (nf < 0 || nf > 7 || nr < 0 || nr > 7) continue;
          final target = b.at(nf, nr);
          if (target != null && target.white != piece.white) {
            out.add(Board.index(nf, nr));
          }
        }
    }
    return out;
  }

  /// ¿La casilla `to` está atacada por alguna pieza de `byWhite`?
  static bool attackedBy(Board b, int to, bool byWhite) {
    for (var i = 0; i < 64; i++) {
      final p = b.atIdx(i);
      if (p == null || p.white != byWhite) continue;
      if (pseudoMoves(b, i).contains(to)) return true;
    }
    return false;
  }

  static int findKing(Board b, bool white) {
    for (var i = 0; i < 64; i++) {
      final p = b.atIdx(i);
      if (p != null && p.white == white && p.kind == 'k') return i;
    }
    return -1;
  }

  /// El bando `white` está en jaque.
  static bool inCheck(Board b, bool white) {
    final k = findKing(b, white);
    if (k < 0) return false;
    return attackedBy(b, k, !white);
  }

  static Board _apply(Board b, int from, int to) {
    final next = List<Piece?>.of(b.cells);
    final moving = next[from]!;
    next[from] = null;
    var moved = moving;
    // Promoción automática a dama (variante simplificada, honesta).
    final lastRank = moving.white ? 0 : 7;
    if (moving.kind == 'p' && lastRank == to ~/ 8) {
      moved = Piece(moving.white, 'q');
    }
    next[to] = moved;
    return Board(next);
  }

  static List<(int, int)> legalMoves(Board b, int from) {
    final attacker = b.atIdx(from)!.white;
    final out = <(int, int)>[];
    for (final to in pseudoMoves(b, from)) {
      final after = _apply(b, from, to);
      final kIndex = findKing(after, attacker);
      if (kIndex < 0) continue;
      if (attackedBy(after, kIndex, !attacker)) continue;
      out.add((from, to));
    }
    return out;
  }

  static List<(int, int)> allLegalMoves(Board b, bool white) {
    final out = <(int, int)>[];
    for (var i = 0; i < 64; i++) {
      final p = b.atIdx(i);
      if (p != null && p.white == white) out.addAll(legalMoves(b, i));
    }
    return out;
  }

  static Board move(Board b, int from, int to) {
    final moves = legalMoves(b, from);
    if (!moves.any((m) => m.$2 == to)) throw ArgumentError('movida ilegal');
    return _apply(b, from, to);
  }

  static String gameState(Board b) {
    // Si falta un rey (capturado en la variante simple), ese bando perdió.
    if (findKing(b, true) < 0) return 'checkmate';
    if (findKing(b, false) < 0) return 'checkmate';
    final whiteMoves = allLegalMoves(b, true);
    if (whiteMoves.isEmpty) {
      return inCheck(b, true) ? 'checkmate' : 'stalemate';
    }
    final blackMoves = allLegalMoves(b, false);
    if (blackMoves.isEmpty) {
      return inCheck(b, false) ? 'checkmate' : 'stalemate';
    }
    return 'playing';
  }

  /// Movida simple del oponente: aleatoria LEGAL, con ligera preferencia por
  /// capturar. Honesto: es un rival didáctico, no una IA mágica.
  static (int, int)? randomMove(Board b, bool white, Random random) {
    final moves = allLegalMoves(b, white);
    if (moves.isEmpty) return null;
    final captures = [
      for (final m in moves)
        if (b.atIdx(m.$2) != null) m,
    ];
    final pool = captures.isNotEmpty && random.nextDouble() < 0.6
        ? captures
        : moves;
    return pool[random.nextInt(pool.length)];
  }
}