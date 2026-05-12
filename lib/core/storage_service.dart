import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _highScoreKey      = 'high_score';
  static const String _soundEnabledKey   = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _totalGamesKey     = 'total_games';
  static const String _totalScoreKey     = 'total_score';

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

  // ── Reset ──────────────────────────────────────────────────
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highScoreKey);
    await prefs.remove(_totalGamesKey);
    await prefs.remove(_totalScoreKey);
    // Note: we keep sound/haptics preferences on reset
    // Players don't want their settings wiped when they reset scores
  }
}