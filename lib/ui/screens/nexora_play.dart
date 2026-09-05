/// NEXORA PLAY — hub de juegos, puntajes y logros (FASE 6).
///
/// HUB solo con datos reales: los puntajes los cuenta [ScoreStore], los
/// logros solo se desbloquean con hechos (capturas, señales, juegos
/// ganados), y cada juego funciona 100% local sin conexión ni assets.
library;

import 'package:flutter/material.dart';

import '../../core/achievements.dart';
import '../../core/achievements_store.dart';
import '../../core/games/phishing_cases.dart';
import '../../core/history_store.dart';
import '../../core/models.dart';
import '../../core/score_store.dart';
import '../games.dart';
import '../theme.dart';
import '../components.dart';
import '../strings.dart';

class NexoraPlayScreen extends StatefulWidget {
  const NexoraPlayScreen({
    super.key,
    required this.strings,
    this.directoryPath,
    this.history = const [],
  });

  final AppStrings strings;

  /// Ruta del sandbox donde viven scores/logros; `null` = solo memoria.
  final String? directoryPath;

  /// Hechos REALES con los que se desbloquean logros de la app.
  final List<HistoryRow> history;

  @override
  State<NexoraPlayScreen> createState() => _NexoraPlayScreenState();
}

class _NexoraPlayScreenState extends State<NexoraPlayScreen> {
  ScoreStore? _scores;
  AchievementStore? _achievements;
  PlayGame? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scores = await ScoreStore.load(widget.directoryPath);
    final achievements = await AchievementStore.load(widget.directoryPath);
    if (!mounted) return;
    setState(() {
      _scores = scores;
      _achievements = achievements;
    });
    await _syncFacts(scores, achievements);
  }

  int get _captureCount => widget.history.length;
  int get _signalCount =>
      widget.history.where((r) => r.severity != Severity.normal).length;

  Future<void> _syncFacts(
    ScoreStore scores,
    AchievementStore achievements,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_captureCount > 0) {
      await achievements.unlock('first_capture', nowMillis: now);
    }
    if (_captureCount >= 5) {
      await achievements.unlock('captures_5', nowMillis: now);
    }
    if (_signalCount > 0) {
      await achievements.unlock('first_signal', nowMillis: now);
    }
    for (final entry in scores.allBest().entries) {
      final def = achievementCatalog.firstWhere((d) => d.game == entry.key);
      if (entry.value >= gameWinThresholdFor(entry.key)) {
        await achievements.unlock(def.id, nowMillis: now);
      }
      if (entry.value >= score100Threshold) {
        await achievements.unlock('score_100', nowMillis: now);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _onGameFinished(PlayGame game, int score, bool won) async {
    final scores = _scores;
    final achievements = _achievements;
    if (scores == null || achievements == null) return;
    await scores.record(game, score);
    final now = DateTime.now().millisecondsSinceEpoch;
    final def = achievementCatalog.firstWhere((d) => d.game == game);
    if (won) await achievements.unlock(def.id, nowMillis: now);
    if (score >= score100Threshold) {
      await achievements.unlock('score_100', nowMillis: now);
    }
    if (mounted) setState(() {});
  }

  void _open(PlayGame game) => setState(() => _active = game);

  void _back() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final active = _active;

    if (active != null) {
      switch (active) {
        case PlayGame.mines:
          return NexoraMinesScreen(
            strings: s,
            onBack: _back,
            onFinished: (score, won) => _onGameFinished(active, score, won),
          );
        case PlayGame.chess:
          return NexoraChessScreen(
            strings: s,
            onBack: _back,
            onFinished: (score, won) => _onGameFinished(active, score, won),
          );
        case PlayGame.firewall:
          return NexoraFirewallScreen(
            strings: s,
            onBack: _back,
            onFinished: (score, won) => _onGameFinished(active, score, won),
          );
        case PlayGame.phishing:
          return NexoraPhishingScreen(
            strings: s,
            onBack: _back,
            onFinished: (score, won) => _onGameFinished(active, score, won),
          );
      }
    }

    final scores = _scores;
    final achievements = _achievements;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NexoraMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(ntPad),
          children: [
            const SizedBox(height: 8),
            Text(
              s.playTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: nexoraGold),
            ),
            const SizedBox(height: ntGapSmall),
            Text(s.playSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              s.playPrivate,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: ntGap),

            SectionHeaderRow(
              icon: Icons.videogame_asset_outlined,
              title: s.playGamesTitle,
            ),
            const SizedBox(height: ntGapSmall),
            for (final game in PlayGame.values) ...[
              _GameCard(
                game: game,
                strings: s,
                best: scores?.best(game) ?? 0,
                last: scores?.recent(game, limit: 1).isNotEmpty == true
                    ? scores!.recent(game, limit: 1).first
                    : -1,
                onOpen: () => _open(game),
              ),
              const SizedBox(height: ntGapSmall),
            ],
            const SizedBox(height: ntGapSmall),

            SectionHeaderRow(
              icon: Icons.emoji_events_outlined,
              title: s.playScoresTitle,
            ),
            const SizedBox(height: ntGapSmall),
            if (scores == null || scores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.playNoScores,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final game in PlayGame.values)
                if (scores.best(game) > 0)
                  _ScoreRow(
                    game: game,
                    best: scores.best(game),
                    last: scores.recent(game, limit: 1).first,
                    strings: s,
                  ),
            const SizedBox(height: ntGap),

            SectionHeaderRow(
              icon: Icons.stars_outlined,
              title: s.playAchievementsTitle,
            ),
            if (achievements != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: ntGapSmall),
                child: Text(
                  '${achievements.unlockedCount} ${s.playAchievementsUnlocked.toLowerCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ),
              for (final def in achievementCatalog) ...[
                _AchievementRow(
                  def: def,
                  unlocked: achievements.isUnlocked(def.id),
                  strings: s,
                ),
                const SizedBox(height: ntGapSmall),
              ],
            ],
            const SizedBox(height: ntGap),
          ],
        ),
      ),
    );
  }
}

int gameWinThresholdFor(PlayGame game) => switch (game) {
  PlayGame.mines => 48, // tablero 8×8 → victoria parcial ya puntúa
  PlayGame.chess => 1,
  PlayGame.firewall => 50,
  PlayGame.phishing => phishingTotal(),
};

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.strings,
    required this.best,
    required this.last,
    required this.onOpen,
  });

  final PlayGame game;
  final AppStrings strings;
  final int best;
  final int last;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final (name, tag, icon, color) = switch (game) {
      PlayGame.mines => (
        strings.gmMines,
        strings.gmMinesTag,
        Icons.grid_on_rounded,
        nexoraGold,
      ),
      PlayGame.chess => (
        strings.gmChess,
        strings.gmChessTag,
        Icons.sports_esports_outlined,
        nexoraBlue,
      ),
      PlayGame.firewall => (
        strings.gmFirewall,
        strings.gmFirewallTag,
        Icons.shield_outlined,
        nexoraRed,
      ),
      PlayGame.phishing => (
        strings.gmPhishing,
        strings.gmPhishingTag,
        Icons.manage_search_outlined,
        nexoraOrange,
      ),
    };
    return NexoraCard(
      padding: const EdgeInsets.all(ntPad),
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(ntRadiusSmall),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: ntGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  tag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ntGapSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                best > 0
                    ? '${strings.playBest} $best${strings.playScoreUnit}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: nexoraGold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                last >= 0
                    ? '${strings.playLast} $last${strings.playScoreUnit}'
                    : '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.game,
    required this.best,
    required this.last,
    required this.strings,
  });

  final PlayGame game;
  final int best;
  final int last;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final label = switch (game) {
      PlayGame.mines => strings.gmMines,
      PlayGame.chess => strings.gmChess,
      PlayGame.firewall => strings.gmFirewall,
      PlayGame.phishing => strings.gmPhishing,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            '${strings.playBest}: $best${strings.playScoreUnit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: nexoraGold,
            ),
          ),
          const SizedBox(width: ntGap),
          Text(
            '${strings.playLast}: $last${strings.playScoreUnit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.def,
    required this.unlocked,
    required this.strings,
  });

  final AchievementDef def;
  final bool unlocked;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color?.withValues(
      alpha: 0.7,
    );
    return NexoraCard(
      padding: const EdgeInsets.symmetric(horizontal: ntPad, vertical: 10),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 22,
            color: unlocked ? nexoraGold : muted,
          ),
          const SizedBox(width: ntGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.achName(def.id),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: unlocked ? nexoraGold : muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked ? strings.achDesc(def.id) : strings.achLockedText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}