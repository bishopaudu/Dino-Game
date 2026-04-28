import 'dart:ui';

/// A single obstacle (cactus) in the game world.
/// 
/// Obstacles are created by the spawn system and destroyed when
/// they move off the left edge of the screen.
class Obstacle {
  /// Horizontal position (left edge). Decreases every frame.
  double x;

  /// Vertical position (top edge). Obstacles sit on the ground.
  double y;

  final double width;
  final double height;

  Obstacle({
    required this.x,
    required this.y,
    this.width = 30,
    this.height = 55,
  });

  /// The axis-aligned bounding box for collision detection.
  Rect get bounds => Rect.fromLTWH(x, y, width, height);
}