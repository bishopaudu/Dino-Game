import 'dart:math';
import 'dart:ui';
import '../models/particle.dart';

/// Manages particle lifecycle — spawning and updating.
class ParticleSystem {
  final List<Particle> particles = [];
  final Random _random = Random();

  // Palette for explosion particles
  static const List<Color> _colors = [
    Color(0xFFFF5252),
    Color(0xFFFFAB40),
    Color(0xFFFFFF00),
    Color(0xFF69F0AE),
    Color(0xFF40C4FF),
    Color(0xFFEA80FC),
  ];

  /// Spawns a burst of particles at the given position.
  void spawnExplosion(double x, double y) {
    for (int i = 0; i < 24; i++) {
      // Random angle covering full 360°
      final angle = _random.nextDouble() * 2 * pi;
      // Random speed between 80 and 320 px/s
      final speed = 80 + _random.nextDouble() * 240;

      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: _colors[_random.nextInt(_colors.length)],
        lifetime: 0.6 + _random.nextDouble() * 0.4, // 0.6 – 1.0 seconds
        radius: 2 + _random.nextDouble() * 4,
      ));
    }
  }

  /// Updates all particles. Call every frame with delta time.
  void update(double dt) {
    for (final p in particles) {
      // Apply velocity
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // Gravity on particles so they arc downward
      p.vy += 600 * dt;

      // Decay lifetime
      p.lifetime -= dt;
    }

    // Remove dead particles
    particles.removeWhere((p) => p.isDead);
  }

  void clear() => particles.clear();
}