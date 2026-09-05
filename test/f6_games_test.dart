/// Tests de la FASE 6 (núcleos de juegos): ajedrez, buscaminas y phishing.
/// Lógica 100% Dart puro, sin Flutter.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/games/chess_engine.dart';
import 'package:nexora_guard/core/games/mines_logic.dart';
import 'package:nexora_guard/core/games/phishing_cases.dart';

void main() {
  group('ChessEngine', () {
    test('la apertura inicial da las 20 jugadas clásicas', () {
      final b = Board.initial();
      expect(ChessEngine.allLegalMoves(b, true).length, 20);
      expect(ChessEngine.allLegalMoves(b, false).length, 20);
    });

    test('el caballo b1 va a a3 y c3 al inicio', () {
      final b = Board.initial();
      final moves = ChessEngine.legalMoves(b, 57).map((m) => m.$2).toList(); // b1
      expect(moves, containsAll([40, 42])); // a3, c3
    });

    test('el peón avanza 1 o 2 desde su casilla de salida', () {
      final b = Board.initial();
      final moves = ChessEngine.pseudoMoves(b, 52).toList(); // e2
      expect(moves, containsAll([44, 36])); // e3, e4
    });

test('detecta jaque: torre negra contra rey blanco', () {
      // Rey blanco e1(60), torre negra e8(4): la columna e está abierta.
      final cells = List<Piece?>.filled(64, null);
      cells[60] = Piece(true, 'k');
      cells[4] = Piece(false, 'r');
      final b = Board(cells);
      expect(ChessEngine.inCheck(b, true), isTrue);
    });

    test('sin rey negro se declara jaque mate (variante honesta)', () {
      final cells = List<Piece?>.of(Board.initial().cells);
      cells[4] = null; // rey negro e8
      expect(ChessEngine.gameState(Board(cells)), 'checkmate');
    });

    test('posiciona un ahogado (stalemate) real', () {
      // Negras: rey a8(0). Blancas: dama c7(10), rey c8(2).
      // c7 cubre a7, b7 y b8; a8 queda libre → negras sin jaque y sin jugada.
      final cells = List<Piece?>.filled(64, null);
      cells[0] = Piece(false, 'k');
      cells[10] = Piece(true, 'q');
      cells[2] = Piece(true, 'k');
      final b = Board(cells);
      expect(ChessEngine.inCheck(b, false), isFalse);
      expect(ChessEngine.gameState(b), 'stalemate');
    });

    test('el peón en la última fila promociona a dama', () {
      // Peón blanco en a7(8): avanza una fila hacia a8(0) y promociona.
      final cells = List<Piece?>.filled(64, null);
      cells[8] = Piece(true, 'p'); // a7
      cells[56] = Piece(true, 'k'); // a1 (rey propio presente)
      cells[63] = Piece(false, 'k'); // h1
      final b = Board(cells);
      final after = ChessEngine.move(b, 8, 0); // a7 → a8
      expect(after.at(0, 0)?.kind, 'q');
      expect(after.at(0, 7)?.white, isTrue);
    });

    test('rechaza jugadas ilegales', () {
      final b = Board.initial();
      expect(
        () => ChessEngine.move(b, 0, 8), // a8 → a7 ocupada por el peón negro
        throwsArgumentError,
      );
    });

    test('randomMove devuelve una jugada legal', () {
      final b = Board.initial();
      final m = ChessEngine.randomMove(b, true, Random(1));
      expect(m, isNotNull);
      expect(
        ChessEngine.legalMoves(b, m!.$1).any((x) => x.$2 == m.$2),
        isTrue,
      );
    });
  });

  group('MinesBoard', () {
    test('el primer toque nunca es mina (muchas semillas)', () {
      for (var seed = 0; seed < 25; seed++) {
        final b = MinesBoard(random: Random(seed));
        expect(b.reveal(0), isNot(MinesAction.exploded));
        expect(b.exploded, isFalse);
        expect(b.revealedCount, greaterThan(0));
      }
    });

    test('las minas se siembran lejos de la primera casilla', () {
      for (var seed = 0; seed < 10; seed++) {
        final b = MinesBoard(random: Random(seed));
        b.reveal(0);
        expect(b.isMine(0), isFalse);
        for (final n in b.neighbors(0)) {
          expect(b.isMine(n), isFalse);
        }
      }
    });

    test('con 0 minas el primer toque gana', () {
      final b = MinesBoard(rows: 3, cols: 3, mines: 0, random: Random(1));
      expect(b.reveal(0), MinesAction.won);
      expect(b.won, isTrue);
    });

    test('el tope de banderas es el número de minas', () {
      final b = MinesBoard(rows: 3, cols: 3, mines: 4, random: Random(2));
      for (var i = 0; i < 4; i++) {
        expect(b.toggleFlag(i), MinesAction.flagged);
      }
      expect(b.toggleFlag(4), MinesAction.noop); // llegó al tope
      expect(b.flagCount, 4);
      expect(b.toggleFlag(0), MinesAction.unflagged);
      expect(b.flagCount, 3);
    });

    test('partida terminada no muda el tablero', () {
      final b = MinesBoard(rows: 3, cols: 3, mines: 0, random: Random(3));
      b.reveal(0);
      expect(b.reveal(1), MinesAction.noop);
      expect(b.toggleFlag(1), MinesAction.noop);
      expect(b.won, isTrue);
    });

    test('la partida siempre termina bien (gana o explota) honestamente', () {
      for (var seed = 10; seed < 16; seed++) {
        final b = MinesBoard(random: Random(seed));
        var finished = false;
        b.reveal(0);
        for (var i = 1; i < 64 && !finished; i++) {
          if (b.isRevealed(i) || b.isFlagged(i)) continue;
          final r = b.reveal(i);
          if (r == MinesAction.exploded || r == MinesAction.won) finished = true;
        }
        expect(finished || b.won || b.exploded, isTrue);
      }
    });
  });

  group('PhishingCase', () {
    test('el catálogo tiene 6 casos con veredictos balanceados', () {
      expect(phishingTotal(), 6);
      expect(phishingFrauds(), 4);
      expect(phishingIsFraud(1), isTrue);
      expect(phishingIsFraud(2), isFalse);
      expect(phishingIsFraud(3), isTrue);
      expect(phishingIsFraud(4), isTrue);
      expect(phishingIsFraud(5), isFalse);
      expect(phishingIsFraud(6), isTrue);
      // id inexistente: falla rápido (no vende un veredicto falso).
      expect(() => phishingIsFraud(99), throwsStateError);
    });
  });
}
