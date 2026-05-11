import 'package:shared_preferences/shared_preferences.dart';

/// Handles reading and writing persistent game data.
/// 
/// Kept as a simple static service — no need for a full repository
/// pattern for a single value.
class StorageService {
  static const String _highScoreKey = 'high_score';

  /// Loads the stored high score. Returns 0 if none saved yet.
  static Future<int> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  /// Saves a new high score. Only call when the score is actually higher.
  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, score);
  }

  /// Clears all saved data. Useful for a "reset" button.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}