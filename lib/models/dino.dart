import 'dart:ui';

/// Represents the player character (the dinosaur).
/// 
/// This is a pure data model — no Flutter widget dependencies.
/// All values are in logical pixels relative to the game canvas.
class Dino {
  /// Current horizontal position (left edge of dino).
  /// The dino never actually moves horizontally — this stays fixed.
  double x;

  /// Current vertical position (top edge of dino).
  /// This changes every frame when jumping or falling.
  double y;

  /// Width of the dino's bounding box in pixels.
  final double width;

  /// Height of the dino's bounding box in pixels.
  final double height;

  /// Vertical velocity in pixels per second.
  /// Negative = moving up (toward top of screen).
  /// Positive = moving down (toward bottom of screen).
  double velocityY;

  /// Whether the dino is currently on the ground.
  /// Used to prevent double-jumping.
  bool isOnGround;

    // ── Animation state ───────────────────────────────────────
  /// Accumulated time used to drive the run cycle animation.
  double animationTime;

  /// Which leg is currently "up" — toggles every step cycle.
  bool leftLegUp;

  Dino({
    required this.x,
    required this.y,
    this.width = 50,
    this.height = 60,
    this.velocityY = 0,
    this.isOnGround = true,
    this.animationTime = 0,
    this.leftLegUp = false,
  });

  /// Returns a [Rect] representing the dino's bounding box.
  /// This is used for collision detection (AABB).
  Rect get bounds => Rect.fromLTWH(x, y, width, height);
}