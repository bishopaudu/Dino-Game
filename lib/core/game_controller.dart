import 'dart:math';
import 'dart:ui';
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
 // late Ground ground;
 // AFTER
Ground ground = Ground();

  // ── Systems ───────────────────────────────────────────────
  final _physicsSystem = PhysicsSystem();
  final _collisionSystem = CollisionSystem();
  final _spawnSystem = SpawnSystem();
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
      _spawnSystem.reset();
      _resetDino();
            _spawnInitialClouds();

      gameState = GameState.playing;
    }
  }

  void handleTap() {
      debugPrint('handleTap called — state: $gameState'); // ← add this

    if (gameState == GameState.playing) {
      _physicsSystem.jump(dino);
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
    if (gameState != GameState.playing) return;

    // 1. Physics
    _physicsSystem.update(dino, groundY, dt);

    // 2. Run animation — only animate legs when on the ground
    _updateDinoAnimation(dt);

    // 3. Scroll ground
    ground.scrollOffset += gameSpeed * dt;

    // 4. Move and cull obstacles
    for (final obs in obstacles) {
      obs.x -= gameSpeed * dt;
    }
    obstacles.removeWhere((obs) => obs.x + obs.width < 0);

    // 5. Move and recycle clouds (parallax: 20% of game speed)
    for (final cloud in clouds) {
      cloud.X -= gameSpeed * 0.2 * dt;
    }
    clouds.removeWhere((cloud) => cloud.X + cloud.width < 0);

    // Spawn a new cloud when one exits
    if (clouds.length < 4 && _random.nextDouble() < 0.005) {
      clouds.add(_createCloud());
    }

    // 6. Spawn obstacles
    final newObstacle = _spawnSystem.update(
      dt, canvasSize.width, groundY, score,
    );
    if (newObstacle != null) {
      obstacles.add(newObstacle);
    }

    // 7. Collision
    if (_collisionSystem.checkCollision(dino, obstacles)) {
      _onGameOver();
      return;
    }

    // 8. Score and speed
    score += (60 * dt).round();
    gameSpeed = 250 + score * 0.5;
  }

  void _updateDinoAnimation(double dt) {
    if (dino.isOnGround) {
      dino.animationTime += dt;
      // Toggle leg every _stepInterval seconds
      if (dino.animationTime >= _stepInterval) {
        dino.animationTime = 0;
        dino.leftLegUp = !dino.leftLegUp;
      }
    } else {
      // Legs together when airborne
      dino.animationTime = 0;
      dino.leftLegUp = false;
    }
  }

  void _onGameOver() {
    if (score > highScore) {
      highScore = score;
    }
    gameState = GameState.gameOver;
  }
}