import 'dart:ui';
import 'package:dino_game/system/collision_system.dart';
import 'package:dino_game/system/physics_system.dart';
import 'package:dino_game/system/spawn_system.dart';

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
  late Dino dino;
  List<Obstacle> obstacles = [];

  // ── Systems ───────────────────────────────────────────────
  final _physicsSystem = PhysicsSystem();
  final _collisionSystem = CollisionSystem();
  final _spawnSystem = SpawnSystem();

  // ── State ─────────────────────────────────────────────────
  GameState gameState = GameState.initial;
  int score = 0;

  // ── World config ──────────────────────────────────────────
  /// The Y coordinate of the ground surface.
  /// Set from screen size when the canvas is first laid out.
  double groundY = 300;

  /// Current horizontal scroll speed in pixels per second.
  double gameSpeed = 250;

  /// Canvas dimensions — set from the actual widget size.
  Size canvasSize = Size.zero;

  // ── Initialization ────────────────────────────────────────

  /// Call once to place the dino at its starting position.
  void initialize(Size size) {
    canvasSize = size;
    groundY = size.height * 0.75; // Ground at 75% down the screen
    _resetDino();
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
      gameState = GameState.playing;
    }
  }

  void handleTap() {
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
  void update(double dt) {
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
  }
}