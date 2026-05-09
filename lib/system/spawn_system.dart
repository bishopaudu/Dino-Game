import 'dart:math';
import 'package:dino_game/models/birds.dart';

import '../models/obstacle.dart';

/// Procedurally spawns obstacles as the game progresses.
/// 
/// Obstacles are never pre-planned — they're generated randomly
/// with increasing frequency as the player's score rises.
/*class SpawnSystem {
  final Random _random = Random();

  /// Time accumulated since the last obstacle was spawned (seconds).
  double _timeSinceLastSpawn = 0;

  /// Minimum gap between spawns in seconds. Decreases with difficulty.
  double _spawnInterval = 2.0;
    double _birdInterval = 5.0;   // birds spawn less often than cacti


  /// Resets the spawn system for a new game.
  void reset() {
    _timeSinceLastSpawn = 0;
    _spawnInterval = 2.0;
    _birdInterval = 5.0;   // birds spawn less often than cacti

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
}*/



class SpawnSystem {
  final Random _random = Random();

  double _timeSinceLastObstacle = 0;
  double _timeSinceLastBird = 0;
  double _obstacleInterval = 2.0;
  double _birdInterval = 5.0;   // birds spawn less often than cacti

  void reset() {
    _timeSinceLastObstacle = 0;
    _timeSinceLastBird = 0;
    _obstacleInterval = 2.0;
    _birdInterval = 5.0;
  }

  /// Returns a new [Obstacle] if one should spawn, else null.
  Obstacle? updateObstacles(
      double dt, double screenWidth, double groundY, int score) {
    _timeSinceLastObstacle += dt;
    _obstacleInterval = (2.0 - score * 0.001).clamp(0.7, 2.0);

    if (_timeSinceLastObstacle < _obstacleInterval) return null;
    _timeSinceLastObstacle = 0;

    // Unlock obstacle variety as score climbs
    final roll = _random.nextDouble();

    if (score > 800 && roll < 0.25) {
      // Wide cactus cluster — two trunks side by side
      return Obstacle(
        x: screenWidth + 10,
        y: groundY - 52,
        width: 64,
        height: 52,
        type: ObstacleType.wideCactus,
      );
    } else if (score > 400 && roll < 0.45) {
      // Tall cactus — harder to jump
      final h = 65.0 + _random.nextDouble() * 20;
      return Obstacle(
        x: screenWidth + 10,
        y: groundY - h,
        width: 32,
        height: h,
        type: ObstacleType.tallCactus,
      );
    } else {
      // Small cactus — always available
      final h = 38.0 + _random.nextDouble() * 18;
      return Obstacle(
        x: screenWidth + 10,
        y: groundY - h,
        width: 28,
        height: h,
        type: ObstacleType.smallCactus,
      );
    }
  }

  /// Returns a new [Bird] if one should spawn, else null.
  /// Birds only appear after score 600.
  Bird? updateBirds(
      double dt, double screenWidth, double groundY, int score) {
    if (score < 600) return null;

    _timeSinceLastBird += dt;
    _birdInterval = (5.0 - score * 0.001).clamp(2.5, 5.0);

    if (_timeSinceLastBird < _birdInterval) return null;
    _timeSinceLastBird = 0;

    // Two flight heights:
    // Low  = just above cactus height → player must jump over
    // High = above jump arc           → player can run under
    final flyLow = _random.nextBool();
    final birdY = flyLow
        ? groundY - 90                  // low — must jump
        : groundY - 160;               // high — duck under (or ignore)

    return Bird(
      x: screenWidth + 10,
      y: birdY,
    );
  }
}