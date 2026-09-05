/// Tests de la FASE 6 (persistencia): ScoreStore y AchievementStore.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/achievements.dart';
import 'package:nexora_guard/core/achievements_store.dart';
import 'package:nexora_guard/core/score_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexora-f6-');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('ScoreStore', () {
    test('sin archivo arranca vacío (memoria)', () async {
      final store = await ScoreStore.load(null);
      expect(store.isEmpty, isTrue);
      expect(store.best(PlayGame.mines), 0);
      expect(store.recent(PlayGame.chess), isEmpty);
    });

    test('registra puntajes y respeta el mejor', () async {
      final store = await ScoreStore.load(dir.path);
      await store.record(PlayGame.mines, 30);
      await store.record(PlayGame.mines, 55);
      await store.record(PlayGame.mines, 10);
      expect(store.best(PlayGame.mines), 55);
      expect(store.recent(PlayGame.mines), [10, 55, 30]);
      expect(store.isEmpty, isFalse);
    });

    test('persiste y se relee igual tras recargar', () async {
final a = await ScoreStore.load(dir.path);
      await a.record(PlayGame.firewall, 62);
      final b = await ScoreStore.load(dir.path);
      expect(b.best(PlayGame.firewall), 62);
      expect(b.recent(PlayGame.firewall), [62]);
    });

    test('archivo corrupto no rompe y sigue en memoria', () async {
      final f = File('${dir.path}/nexora-scores.json');
      await f.writeAsString('{json roto');
      final store = await ScoreStore.load(dir.path);
      expect(store.isEmpty, isTrue);
      await store.record(PlayGame.chess, 7);
      expect(store.best(PlayGame.chess), 7);
    });

    test('recent limita a los últimos N, más reciente primero', () async {
      final store = await ScoreStore.load(null);
      for (var i = 1; i <= 7; i++) {
        await store.record(PlayGame.mines, i);
      }
      expect(store.recent(PlayGame.mines, limit: 3), [7, 6, 5]);
    });
  });

  group('AchievementStore', () {
    test('sin archivo no hay logros desbloqueados', () async {
      final store = await AchievementStore.load(null);
      expect(store.unlockedCount, 0);
      expect(store.isUnlocked('first_capture'), isFalse);
    });

    test('desbloquea y persiste', () async {
      final a = await AchievementStore.load(dir.path);
      await a.unlock('first_capture', nowMillis: 1);
      await a.unlock('captures_5', nowMillis: 2);
      expect(a.unlocked().map((x) => x.id), contains('first_capture'));
      expect(a.isUnlocked('captures_5'), isTrue);

      final b = await AchievementStore.load(dir.path);
      expect(b.isUnlocked('first_capture'), isTrue);
      expect(b.unlockedCount, 2);
    });

    test('un bloqueo doble no duplica ni mueve la fecha', () async {
      final a = await AchievementStore.load(null);
      await a.unlock('mines_win', nowMillis: 1000);
      await a.unlock('mines_win', nowMillis: 9999);
      expect(a.unlockedCount, 1);
      expect(a.unlocked().single.earnedAtMillis, 1000);
    });
  });

  group('achievementCatalog', () {
    test('el catálogo cubre todos los logros y pivotes pedidos', () {
      final ids = achievementCatalog.map((d) => d.id).toList();
      expect(ids, containsAll(['first_capture', 'captures_5', 'first_signal']));
      expect(ids, containsAll(['score_100', 'mines_win', 'chess_win', 'firewall_win', 'phishing_all']));
      expect(ids.length, 8);
      expect(score100Threshold, 100);
    });
  });

  test('cada logro tiene id estable y juego asociado coherente', () {
    for (final d in achievementCatalog) {
      expect(d.id, isNotEmpty);
    }
    expect(
      achievementCatalog.where((d) => d.game == PlayGame.mines).single.id,
      'mines_win',
    );
    expect(
      achievementCatalog.firstWhere((d) => d.id == 'score_100').game,
      isNull,
    );
  });
}
