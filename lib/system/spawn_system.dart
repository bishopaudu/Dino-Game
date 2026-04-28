import 'dart:math';
import '../models/obstacle.dart';

/// Procedurally spawns obstacles as the game progresses.
/// 
/// Obstacles are never pre-planned — they're generated randomly
/// with increasing frequency as the player's score rises.
class SpawnSystem {
  final Random _random = Random();

  /// Time accumulated since the last obstacle was spawned (seconds).
  double _timeSinceLastSpawn = 0;

  /// Minimum gap between spawns in seconds. Decreases with difficulty.
  double _spawnInterval = 2.0;

  /// Resets the spawn system for a new game.
  void reset() {
    _timeSinceLastSpawn = 0;
    _spawnInterval = 2.0;
  }

  /// Call every frame. Returns a new [Obstacle] if one should spawn, else null.
  ///
  /// [dt]          - delta time in seconds
  /// [screenWidth] - how far right obstacles should spawn
  /// [groundY]     - where the ground surface is (obstacles sit on it)
  /// [score]       - current score, used to scale difficulty
  Obstacle? update(double dt, double screenWidth, double groundY, int score) {
    _timeSinceLastSpawn += dt;

    // Scale difficulty: reduce spawn interval as score increases.
    // Clamp to 0.8s minimum so the game never becomes impossible.
    _spawnInterval = (2.0 - score * 0.002).clamp(0.8, 2.0);

    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;

      // Randomly vary obstacle size to keep it interesting.
      final height = 40.0 + _random.nextDouble() * 30.0; // 40-70px tall
      final width = 25.0 + _random.nextDouble() * 20.0;  // 25-45px wide

      return Obstacle(
        x: screenWidth + 10,       // Just off the right edge
        y: groundY - height,       // Sitting on the ground
        width: width,
        height: height,
      );
    }

    return null;
  }
}