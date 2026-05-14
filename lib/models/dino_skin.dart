import 'package:flutter/material.dart';

/// Defines a single dino skin — visual theme applied to the dino.
/// 
/// Instead of sprite images (which we'd need separate art for),
/// each skin is a set of colors applied to the existing shape renderer.
/// This way we get 5 distinct-looking dinos with zero new assets.
class DinoSkin {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int unlockScore;      // score needed to permanently unlock

  // Colors applied to the dino painter
  final Color bodyColor;
  final Color legColor;
  final Color eyeColor;
  final Color pupilColor;
  final Color outlineColor;   // subtle outline for some skins

  const DinoSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.unlockScore,
    required this.bodyColor,
    required this.legColor,
    required this.eyeColor,
    this.pupilColor = const Color(0xFF222222),
    this.outlineColor = Colors.transparent,
  });
}

/// All available skins. Add new skins here — the UI picks them up automatically.
class DinoSkins {
  static const List<DinoSkin> all = [
    DinoSkin(
      id: 'classic',
      name: 'Classic',
      description: 'The original. Never goes out of style.',
      emoji: '🦕',
      unlockScore: 0,           // always unlocked
      bodyColor:  Color(0xFF555555),
      legColor:   Color(0xFF444444),
      eyeColor:   Color(0xFFF7F7F7),
    ),
    DinoSkin(
      id: 'ghost',
      name: 'Ghost',
      description: 'Unlock at 500 points. Spooky and pale.',
      emoji: '👻',
      unlockScore: 500,
      bodyColor:  Color(0xFFDDDDEE),
      legColor:   Color(0xFFBBBBCC),
      eyeColor:   Color(0xFF9999FF),
      pupilColor: Color(0xFF6666CC),
    ),
    DinoSkin(
      id: 'robot',
      name: 'Robot',
      description: 'Unlock at 1500 points. Cold and metallic.',
      emoji: '🤖',
      unlockScore: 1500,
      bodyColor:  Color(0xFF4488CC),
      legColor:   Color(0xFF336699),
      eyeColor:   Color(0xFF00FFFF),
      pupilColor: Color(0xFF0088AA),
    ),
    DinoSkin(
      id: 'lava',
      name: 'Lava',
      description: 'Unlock at 3000 points. Born from fire.',
      emoji: '🌋',
      unlockScore: 3000,
      bodyColor:  Color(0xFFCC4422),
      legColor:   Color(0xFFAA3311),
      eyeColor:   Color(0xFFFFAA00),
      pupilColor: Color(0xFFFF4400),
    ),
    DinoSkin(
      id: 'shadow',
      name: 'Shadow',
      description: 'Unlock at 5000 points. Pure darkness.',
      emoji: '🌑',
      unlockScore: 5000,
      bodyColor:  Color(0xFF111122),
      legColor:   Color(0xFF000011),
      eyeColor:   Color(0xFFFF00FF),
      pupilColor: Color(0xFFCC00CC),
      outlineColor: Color(0xFF6600CC),
    ),
  ];

  static DinoSkin getById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}