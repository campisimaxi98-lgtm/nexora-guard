/// Puntajes de NEXORA PLAY — Dart puro (`dart:io` + JSON), sin dependencias.
///
/// Mejores puntajes y últimas partidas por juego. Un archivo corrupto
/// degrada a memoria vacía: el hub funciona igual, solo pierde el historial.
library;

import 'dart:convert';
import 'dart:io';

enum PlayGame { mines, chess, firewall, phishing }

class ScoreEntry {
  const ScoreEntry({
    required this.game,
    required this.score,
    required this.timestampMillis,
  });

  final PlayGame game;
  final int score;
  final int timestampMillis;
}

class ScoreStore {
  ScoreStore._(this._scores, this._file);

  static const _bestKey = 'best';
  static const _recentKey = 'recent';

  final File? _file;
  final Map<String, dynamic> _scores;

  /// Carga el store. Con `directoryPath == null` opera SOLO en memoria
  /// (útil en tests y en sesiones sin acceso a disco).
  static Future<ScoreStore> load(String? directoryPath) async {
    if (directoryPath == null) return ScoreStore._({}, null);
    final file = File('$directoryPath/nexora-scores.json');
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) return ScoreStore._(decoded, file);
      }
    } on FileSystemException {
      // Sin acceso al disco: store en memoria.
    } on FormatException {
      // Archivo corrupto: store en memoria.
    }
    return ScoreStore._({}, file);
  }

  static String _gameName(PlayGame g) => g.name;

  int _best(PlayGame game) => _asInt(_scores[_bestKey]?[_gameName(game)]);

  static int _asInt(Object? v) => v is num ? v.toInt().clamp(0, 1000000) : 0;

  int best(PlayGame game) => _best(game);

  List<int> recent(PlayGame game, {int limit = 5}) {
    final list = _scores[_recentKey]?[_gameName(game)];
    if (list is! List) return const [];
    final ints = [for (final v in list) _asInt(v)];
    final tail = ints.length > limit ? ints.sublist(ints.length - limit) : ints;
    return tail.reversed.toList();
  }

  Map<PlayGame, int> allBest() => {
    for (final g in PlayGame.values) g: _best(g),
  };

  bool get isEmpty => PlayGame.values.every((g) => _best(g) <= 0);

  /// Registra una partida terminada y persiste (si hay archivo).
  Future<void> record(PlayGame game, int score) async {
    final safe = score.clamp(0, 1000000);
    final bestMap = Map<String, dynamic>.from(
      _scores[_bestKey] is Map ? _scores[_bestKey] as Map : const {},
    );
    bestMap[_gameName(game)] = safe > _asInt(bestMap[_gameName(game)])
        ? safe
        : _asInt(bestMap[_gameName(game)]);
    _scores[_bestKey] = bestMap;

    final recentMap = Map<String, dynamic>.from(
      _scores[_recentKey] is Map ? _scores[_recentKey] as Map : const {},
    );
    final list = List<dynamic>.from(
      recentMap[_gameName(game)] is List ? recentMap[_gameName(game)] as List : const [],
    )..add(safe);
    // Solo los últimos 20 por juego: el archivo no engorda sin límite.
    if (list.length > 20) list.removeRange(0, list.length - 20);
    recentMap[_gameName(game)] = list;
    _scores[_recentKey] = recentMap;

    await _persist();
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_scores), flush: true);
    } on FileSystemException {
      // Sin acceso al disco, el puntaje vive en la sesión.
    }
  }
}