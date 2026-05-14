import 'dart:convert';

import 'package:dino_game/models/achievement.dart';
import 'package:dino_game/models/run_model.dart';
import 'package:dino_game/system/achievments_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _highScoreKey      = 'high_score';
  static const String _soundEnabledKey   = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _totalGamesKey     = 'total_games';
  static const String _totalScoreKey     = 'total_score';
  static const String _achievementsKey     = 'achievements';
  static const String _selectedSkinKey     = 'selected_skin';
  static const String _unlockedSkinsKey    = 'unlocked_skins';
  static const String _runHistoryKey       = 'run_history';

    static const int _maxRunHistory = 10; // keep last 10 runs


  // ── High score ─────────────────────────────────────────────
  static Future<int> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, score);
  }

  // ── Sound ──────────────────────────────────────────────────
  static Future<bool> loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true; // on by default
  }

  static Future<void> saveSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }

  // ── Haptics ────────────────────────────────────────────────
  static Future<bool> loadHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsEnabledKey) ?? true; // on by default
  }

  static Future<void> saveHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, value);
  }

  // ── Stats ──────────────────────────────────────────────────
  static Future<void> incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalGamesKey) ?? 0;
    await prefs.setInt(_totalGamesKey, current + 1);
  }

  static Future<int> loadTotalGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalGamesKey) ?? 0;
  }

  static Future<void> addToTotalScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalScoreKey) ?? 0;
    await prefs.setInt(_totalScoreKey, current + score);
  }

  static Future<int> loadTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalScoreKey) ?? 0;
  }


    // ── Achievements ───────────────────────────────────────────

  /// Loads saved achievement states and applies them to the definitions list.
  static Future<List<Achievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_achievementsKey);

    // Start from fresh definitions every time
    final achievements = AchievementSystem.definitions
        .map((a) => Achievement(
              id:          a.id,
              title:       a.title,
              description: a.description,
              emoji:       a.emoji,
              tier:        a.tier,
            ))
        .toList();

    if (jsonStr == null) return achievements;

    try {
      final Map<String, dynamic> saved = jsonDecode(jsonStr);
      for (final achievement in achievements) {
        if (saved.containsKey(achievement.id)) {
          achievement.applyJson(
              saved[achievement.id] as Map<String, dynamic>);
        }
      }
    } catch (_) {
      // Corrupted data — return fresh list
    }

    return achievements;
  }

  static Future<void> saveAchievements(
      List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final a in achievements) a.id: a.toJson()};
    await prefs.setString(_achievementsKey, jsonEncode(map));
  }

  // ── Skins ──────────────────────────────────────────────────

  static Future<String> loadSelectedSkin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedSkinKey) ?? 'classic';
  }

  static Future<void> saveSelectedSkin(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSkinKey, skinId);
  }

  static Future<Set<String>> loadUnlockedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedSkinsKey) ?? ['classic'];
    return list.toSet();
  }

  static Future<void> saveUnlockedSkins(Set<String> skinIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedSkinsKey, skinIds.toList());
  }

  // ── Run history ────────────────────────────────────────────

  static Future<List<RunRecord>> loadRunHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_runHistoryKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => RunRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRunRecord(RunRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadRunHistory();

    // Add new record at front, keep only last N runs
    history.insert(0, record);
    if (history.length > _maxRunHistory) {
      history.removeRange(_maxRunHistory, history.length);
    }

    final jsonStr = jsonEncode(history.map((r) => r!.toJson()).toList());
    await prefs.setString(_runHistoryKey, jsonStr);
  }

  // ── Reset ──────────────────────────────────────────────────
    static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highScoreKey);
    await prefs.remove(_totalGamesKey);
    await prefs.remove(_totalScoreKey);
    await prefs.remove(_achievementsKey);
    await prefs.remove(_unlockedSkinsKey);
    await prefs.remove(_runHistoryKey);
    await prefs.remove(_selectedSkinKey);
    // Preserve sound/haptics preferences
  }
}