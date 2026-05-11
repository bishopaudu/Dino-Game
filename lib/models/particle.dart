import 'dart:ui';

/// A single particle in a collision explosion effect.
/// 
/// Each particle has an independent velocity and fades out
/// as its lifetime decreases toward zero.
class Particle {
  /// Current position in canvas space.
  double x;
  double y;

  /// Velocity in pixels per second.
  double vx;
  double vy;

  /// Color of this particle.
  final Color color;

  /// Remaining lifetime from 1.0 (just spawned) to 0.0 (dead).
  double lifetime;

  /// Radius of the particle circle.
  final double radius;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.lifetime = 1.0,
    this.radius = 4.0,
  });

  /// Returns true when the particle should be removed.
  bool get isDead => lifetime <= 0;
}