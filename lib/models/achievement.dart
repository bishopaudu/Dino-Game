/// Defines a single achievement and its unlock state.
/// 
/// The definition (name, description, condition) is compile-time constant.
/// The state (isUnlocked, unlockedAt) is persisted to storage.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;         // shown in the trophy room
  final AchievementTier tier; // bronze, silver, gold

  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  void applyJson(Map<String, dynamic> json) {
    isUnlocked  = json['isUnlocked'] as bool? ?? false;
    final dateStr = json['unlockedAt'] as String?;
    unlockedAt  = dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
}

enum AchievementTier { bronze, silver, gold }