import '../models/dino.dart';
import '../models/obstacle.dart';

/// Detects collisions between the dino and obstacles.
/// 
/// Uses Axis-Aligned Bounding Box (AABB) detection:
/// two rectangles collide if they overlap on BOTH the X and Y axes.
class CollisionSystem {
  /// Returns true if the dino is colliding with any obstacle.
  /// 
  /// AABB formula:
  ///   collides = (A.left < B.right) AND (A.right > B.left)
  ///          AND (A.top  < B.bottom) AND (A.bottom > B.top)
  bool checkCollision(Dino dino, List<Obstacle> obstacles) {
    // Add a small inset to make the hitbox slightly smaller than visual.
    // This feels fairer to the player — pixel-perfect hits feel cheap.
    final dinoBounds = dino.bounds.deflate(6);

    for (final obstacle in obstacles) {
      final obstacleBounds = obstacle.bounds.deflate(4);

      // overlapsX: the rectangles share some horizontal space
      final overlapsX = dinoBounds.left < obstacleBounds.right &&
          dinoBounds.right > obstacleBounds.left;

      // overlapsY: the rectangles share some vertical space
      final overlapsY = dinoBounds.top < obstacleBounds.bottom &&
          dinoBounds.bottom > obstacleBounds.top;

      // A collision requires overlap on BOTH axes simultaneously.
      if (overlapsX && overlapsY) {
        return true;
      }
    }
    return false;
  }
}