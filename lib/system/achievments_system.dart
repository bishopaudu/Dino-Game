import '../models/achievement.dart';

/// Defines all achievements and evaluates unlock conditions.
/// 
/// Achievements are checked at two points:
///   1. On game over — score and run-based achievements
///   2. During gameplay — survival time achievements
/// 
/// Returns a list of newly unlocked achievements each evaluation
/// so the UI can show unlock banners.
class AchievementSystem {
  /// The master list of all achievements in the game.
  /// Add new achievements here — evaluation logic below picks them up.
  static final List<Achievement> definitions = [
    // ── Score milestones ──────────────────────────────────────
    Achievement(
      id: 'score_500',
      title: 'Getting Warmed Up',
      description: 'Score 500 points in a single run',
      emoji: '🔥',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'score_1000',
      title: 'Four Figures',
      description: 'Score 1,000 points in a single run',
      emoji: '⭐',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'score_2500',
      title: 'Unstoppable',
      description: 'Score 2,500 points in a single run',
      emoji: '🚀',
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'score_5000',
      title: 'Legend',
      description: 'Score 5,000 points in a single run',
      emoji: '🏆',
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'score_10000',
      title: 'Dino God',
      description: 'Score 10,000 points in a single run',
      emoji: '👑',
      tier: AchievementTier.gold,
    ),

    // ── Survival ──────────────────────────────────────────────
    Achievement(
      id: 'survive_30',
      title: 'Still Standing',
      description: 'Survive for 30 seconds',
      emoji: '⏱️',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'survive_120',
      title: 'Marathon Runner',
      description: 'Survive for 2 minutes',
      emoji: '🏃',
      tier: AchievementTier.silver,
    ),

    // ── Persistence ───────────────────────────────────────────
    Achievement(
      id: 'games_10',
      title: 'Dedicated',
      description: 'Play 10 games',
      emoji: '🎮',
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'games_50',
      title: 'Obsessed',
      description: 'Play 50 games',
      emoji: '💪',
      tier: AchievementTier.silver,
    ),

    // ── Secret ────────────────────────────────────────────────
    Achievement(
      id: 'night_survivor',
      title: 'Creature of the Night',
      description: 'Score 1,000 points during night time',
      emoji: '🌙',
      tier: AchievementTier.silver,
    ),
  ];

  /// Evaluates which achievements should unlock given current game stats.
  /// Returns only the NEWLY unlocked achievements (not already unlocked ones).
  List<Achievement> evaluate({
    required List<Achievement> current,
    required int score,
    required int totalGames,
    required int survivalSeconds,
    required double timeOfDay,   // 0=day, 1=night
  }) {
    final newUnlocks = <Achievement>[];

    for (final achievement in current) {
      if (achievement.isUnlocked) continue; // skip already unlocked

      final shouldUnlock = _check(
        id:              achievement.id,
        score:           score,
        totalGames:      totalGames,
        survivalSeconds: survivalSeconds,
        timeOfDay:       timeOfDay,
      );

      if (shouldUnlock) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newUnlocks.add(achievement);
      }
    }

    return newUnlocks;
  }

  bool _check({
    required String id,
    required int score,
    required int totalGames,
    required int survivalSeconds,
    required double timeOfDay,
  }) {
    switch (id) {
     case 'score_500':    return score >= 500;
   // case 'score_500': return score >= 10;
      case 'score_1000':   return score >= 1000;
      case 'score_2500':   return score >= 2500;
      case 'score_5000':   return score >= 5000;
      case 'score_10000':  return score >= 10000;
      case 'survive_30':   return survivalSeconds >= 30;
      case 'survive_120':  return survivalSeconds >= 120;
      case 'games_10':     return totalGames >= 10;
      case 'games_50':     return totalGames >= 50;
      case 'night_survivor':
        // Must score 1000 AND be in night time (timeOfDay > 0.5)
        return score >= 1000 && timeOfDay > 0.5;
      default:             return false;
    }
  }
}