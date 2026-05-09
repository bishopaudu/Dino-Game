import 'dart:math';
import 'dart:ui';
import 'package:dino_game/models/birds.dart';
import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/models/ground.dart';
import 'package:dino_game/system/collision_system.dart';
import 'package:dino_game/system/physics_system.dart';
import 'package:dino_game/system/spawn_system.dart';
import 'package:flutter/material.dart';

import '../models/dino.dart';
import '../models/obstacle.dart';
import 'game_state.dart';

/// Central controller that owns all game entities and systems.
/// 
/// Responsibilities:
/// - Holds references to all game objects (dino, obstacles)
/// - Coordinates systems (physics, collision, spawning)
/// - Runs the update loop
/// - Manages game state transitions
/// - Exposes state for the UI to read
class GameController {
  // ── Entities ──────────────────────────────────────────────
  //late Dino dino;
  // AFTER
Dino dino = Dino(x: 0, y: 0);  // placeholder, overwritten by initialize()
  List<Obstacle> obstacles = [];
   List<Clouds> clouds = [];
     List<Bird> birds = [];

 // late Ground ground;
 // AFTER
Ground ground = Ground();

// ── Day/night ─────────────────────────────────────────────
  /// 0.0 = full day, 1.0 = full night. Cycles back to day.
  double timeOfDay = 0.0;

  // ── Collision flash ───────────────────────────────────────
  /// Counts down after a collision for the flash effect.
  double flashTimer = 0.0;
  static const double _flashDuration = 0.25;

  // ── Systems ───────────────────────────────────────────────
  // ── Systems ───────────────────────────────────────────────
  final _physics = PhysicsSystem();
  final _collision = CollisionSystem();
  final _spawner = SpawnSystem();
  final _random = Random();


  // ── State ─────────────────────────────────────────────────
  GameState gameState = GameState.initial;
  int score = 0;
  int highScore = 0; 
  // ── World config ──────────────────────────────────────────
  /// The Y coordinate of the ground surface.
  /// Set from screen size when the canvas is first laid out.
  double groundY = 300;

  /// Current horizontal scroll speed in pixels per second.
  double gameSpeed = 250;

  /// Canvas dimensions — set from the actual widget size.
  Size canvasSize = Size.zero;

  // ── Run animation config ──────────────────────────────────
  static const double _stepInterval = 0.15; // seconds per leg alternation

int initCloudValue  =4;

  // ── Initialization ────────────────────────────────────────

  /// Call once to place the dino at its starting position.
  void initialize(Size size) {
    canvasSize = size;
    groundY = size.height * 0.75; // Ground at 75% down the screen
    _resetDino();
        _spawnInitialClouds();
  }

  void _spawnInitialClouds(){
    clouds.clear();
    for (int i = 0; i < initCloudValue; i++) {
      clouds.add(_createCloud(
        x: _random.nextDouble() * canvasSize.width,
      ));
    }
  }
 Clouds _createCloud({double? x}) {
    return Clouds(
      X: x ?? canvasSize.width + 50,
      Y: 40 + _random.nextDouble() * (groundY * 0.4),
      width: 60 + _random.nextDouble() * 80, // 60-140px wide
      opacity: 0.4 + _random.nextDouble() * 0.5,
    );
  }

  void _resetDino() {
    dino = Dino(
      x: canvasSize.width * 0.15,  // 15% from left edge
      y: groundY - 60,              // Sitting on ground
    );
  }

  // ── Game lifecycle ─────────────────────────────────────────

  void startGame() {
    if (gameState == GameState.initial || gameState == GameState.gameOver) {
      obstacles.clear();
      score = 0;
      gameSpeed = 250;
        timeOfDay = 0.0;
    flashTimer = 0.0;
      _spawner.reset();
      _resetDino();
            _spawnInitialClouds();

      gameState = GameState.playing;
    }
  }

  void handleTap() {
      debugPrint('handleTap called — state: $gameState'); // ← add this

    if (gameState == GameState.playing) {
      _physics.jump(dino);
    } else if (gameState == GameState.initial || gameState == GameState.gameOver) {
      startGame();
    }
  }

  // ── Main update loop ───────────────────────────────────────

  /// Called every frame by the game loop with delta time in seconds.
  /// 
  /// Order matters:
  ///   1. Update physics (move the dino)
  ///   2. Update obstacles (move them left)
  ///   3. Spawn new obstacles
  ///   4. Check collisions
  ///   5. Update score
  /*void update(double dt) {
    if (gameState != GameState.playing) return;

    // 1. Physics
    _physicsSystem.update(dino, groundY, dt);

    // 2. Move obstacles left
    for (final obs in obstacles) {
      obs.x -= gameSpeed * dt;
    }

    // 3. Remove obstacles that have scrolled off-screen
    obstacles.removeWhere((obs) => obs.x + obs.width < 0);

    // 4. Spawn new obstacles
    final newObstacle = _spawnSystem.update(
      dt,
      canvasSize.width,
      groundY,
      score,
    );
    if (newObstacle != null) {
      obstacles.add(newObstacle);
    }

    // 5. Collision detection
    if (_collisionSystem.checkCollision(dino, obstacles)) {
      gameState = GameState.gameOver;
      return;
    }

    // 6. Score: increments with time played (not pixel distance)
    // 60 points per second is a good baseline.
    score += (60 * dt).round();

    // 7. Gradually increase speed over time
    gameSpeed = 250 + score * 0.5;
  }*/

  void update(double dt) {
    // Flash timer ticks even on game over (finishes the flash effect)
    if (flashTimer > 0) flashTimer = (flashTimer - dt).clamp(0, _flashDuration);

    if (gameState != GameState.playing) return;

    // 1. Physics + animation
    _physics.update(dino, groundY, dt);
    _updateDinoAnimation(dt);

    // 2. Day/night — full cycle every ~120 seconds of play
    timeOfDay = (timeOfDay + dt / 120.0) % 1.0;

    // 3. Ground scroll
    ground.scrollOffset += gameSpeed * dt;

    // 4. Move obstacles
    for (final obs in obstacles) {
      obs.x -= gameSpeed * dt;
    }
    obstacles.removeWhere((o) => o.x + o.width < 0);

    // 5. Move birds — slightly faster than ground speed
    for (final bird in birds) {
      bird.x -= gameSpeed * 1.3 * dt;
      bird.flapTime += dt;
    }
    birds.removeWhere((b) => b.x + b.width < 0);

    // 6. Clouds (parallax)
    for (final cloud in clouds) {
      cloud.X -= gameSpeed * 0.2 * dt;
    }
    clouds.removeWhere((c) => c.X + c.width < 0);
    if (clouds.length < 4 && _random.nextDouble() < 0.005) {
      clouds.add(_createCloud());
    }

    // 7. Spawn
    final newObs = _spawner.updateObstacles(
        dt, canvasSize.width, groundY, score);
    if (newObs != null) obstacles.add(newObs);

    final newBird = _spawner.updateBirds(
        dt, canvasSize.width, groundY, score);
    if (newBird != null) birds.add(newBird);

    // 8. Collision
    if (_collision.checkCollision(dino, obstacles) ||
        _checkBirdCollision()) {
      _onGameOver();
      return;
    }

    // 9. Score + speed
    score += (60 * dt).round();
    gameSpeed = 250 + score * 0.5;
  }

  bool _checkBirdCollision() {
    final dinoBounds = dino.bounds.deflate(6);
    for (final bird in birds) {
      if (dinoBounds.overlaps(bird.bounds)) return true;
    }
    return false;
  }

  void _updateDinoAnimation(double dt) {
    if (dino.isOnGround) {
      dino.animationTime += dt;
      if (dino.animationTime >= _stepInterval) {
        dino.animationTime = 0;
        dino.leftLegUp = !dino.leftLegUp;
      }
    } else {
      dino.animationTime = 0;
      dino.leftLegUp = false;
    }
  }

  void _onGameOver() {
    if (score > highScore) highScore = score;
    flashTimer = _flashDuration;   // trigger flash
    gameState = GameState.gameOver;
  }
}