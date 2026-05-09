import 'dart:ui';

/// A flying obstacle that appears at one of two heights.
/// Birds move faster than cacti and require the player to duck
/// (we'll add ducking in Milestone 4 — for now they're just
/// a visual threat at head height or a passable low flyer).
class Bird {
  double x;
  double y;
  final double width;
  final double height;

  /// Accumulated time used to drive the wing-flap sine animation.
  double flapTime;

  Bird({
    required this.x,
    required this.y,
    this.width = 46,
    this.height = 24,
    this.flapTime = 0,
  });

  /// Bounding box for collision detection.
  /// Slightly inset so grazing passes don't feel unfair.
  Rect get bounds => Rect.fromLTWH(
        x + width * 0.1,
        y + height * 0.15,
        width * 0.8,
        height * 0.7,
      );
}