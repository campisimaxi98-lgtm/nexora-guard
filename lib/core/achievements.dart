/// Catálogo de logros de NEXORA PLAY.
///
/// Cada logro declara el HECHO REAL que lo desbloquea. La UI consulta al
/// catálogo para saber, en cada idioma, qué nombre y descripción mostrar; el
/// desbloqueo lo decide el dato real del dispositivo (capturas del
/// HistoryStore, juegos ganados, puntajes), jamás un número al azar.
library;

import 'score_store.dart';

class AchievementDef {
  const AchievementDef({required this.id, required this.game});

  final String id;

  /// Juego asociado, si lo hay (`PlayGame`); null para logros de la app.
  final PlayGame? game;
}

/// Orden de muestra del hub (estable, no depende del mapa).
const List<AchievementDef> achievementCatalog = [
  AchievementDef(id: 'first_capture', game: null),
  AchievementDef(id: 'captures_5', game: null),
  AchievementDef(id: 'first_signal', game: null),
  AchievementDef(id: 'score_100', game: null),
  AchievementDef(id: 'mines_win', game: PlayGame.mines),
  AchievementDef(id: 'chess_win', game: PlayGame.chess),
  AchievementDef(id: 'firewall_win', game: PlayGame.firewall),
  AchievementDef(id: 'phishing_all', game: PlayGame.phishing),
];

/// Umbral de "score_100": primer puntaje ≥ 100 en cualquier juego.
const int score100Threshold = 100;

/// Puntaje mínimo (no-victoria) con el que un juego ya cuenta como "jugado".
const int playedScoreFloor = 1;