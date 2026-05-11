import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Holds all loaded sprite images for the game.
/// 
/// Images are loaded once at app startup via [SpriteLoader.load()].
/// Every field is nullable — if an image fails to load, the painter
/// falls back to drawing primitive shapes instead.
class GameSprites {
  final ui.Image? dinoRun1;
  final ui.Image? dinoRun2;
  final ui.Image? dinoDuck;
  final ui.Image? dinoJump;
  final ui.Image? cactusSmall;
  final ui.Image? cactusTall;
  final ui.Image? cactusWide;
  final ui.Image? bird1;
  final ui.Image? bird2;

  const GameSprites({
    this.dinoRun1,
    this.dinoRun2,
    this.dinoDuck,
    this.dinoJump,
    this.cactusSmall,
    this.cactusTall,
    this.cactusWide,
    this.bird1,
    this.bird2,
  });

  /// Empty sprites — all null. Used before loading completes.
  static const GameSprites empty = GameSprites();
}

/// Loads all sprite images from the assets folder.
class SpriteLoader {
  /// Attempts to load all sprites. 
  /// Any image that fails to load is silently set to null —
  /// the game continues with shape fallbacks.
  static Future<GameSprites> load() async {
    return GameSprites(
      dinoRun1:    await _tryLoad('assets/images/dino_run1.png'),
      dinoRun2:    await _tryLoad('assets/images/dino_run2.png'),
      dinoDuck:    await _tryLoad('assets/images/dino_duck.png'),
      dinoJump:    await _tryLoad('assets/images/dino_jump.png'),
      cactusSmall: await _tryLoad('assets/images/cactus_small.png'),
      cactusTall:  await _tryLoad('assets/images/cactus_tall.png'),
      cactusWide:  await _tryLoad('assets/images/cactus_wide.png'),
      bird1:       await _tryLoad('assets/images/bird1.png'),
      bird2:       await _tryLoad('assets/images/bird2.png'),
    );
  }

  static Future<ui.Image?> _tryLoad(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      // Asset missing or failed — return null, painter uses shape fallback
      return null;
    }
  }
}