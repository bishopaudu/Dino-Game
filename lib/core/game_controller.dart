import 'dart:math';
import 'package:dino_game/models/birds.dart';
import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/models/ground.dart';
import 'package:dino_game/models/particle.dart';
import 'package:dino_game/system/collision_system.dart';
import 'package:dino_game/system/milestone_system.dart';
import 'package:dino_game/system/partilce_system.dart';
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
/*class GameController {
  // ── Entities ──────────────────────────────────────────────
Dino dino = Dino(x: 0, y: 0);  // placeholder, overwritten by initialize()
  List<Obstacle> obstacles = [];
  List<Clouds> clouds = [];
  List<Bird> birds = [];
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
}*/


/*class GameController {
  // ── Entities ──────────────────────────────────────────────
  Dino dino = Dino(x: 0, y: 0);
  List<Obstacle> obstacles = [];
  List<Bird> birds = [];
  List<Clouds> clouds = [];
  Ground ground = Ground();

  // ── Systems ───────────────────────────────────────────────
  final _physics    = PhysicsSystem();
  final _collision  = CollisionSystem();
  final _spawner    = SpawnSystem();
  final _particles  = ParticleSystem();
  final _milestones = MilestoneSystem();
  final _random     = Random();

  // ── State ─────────────────────────────────────────────────
  GameState gameState = GameState.initial;
  int score     = 0;
  int highScore = 0;

  // ── Effects ───────────────────────────────────────────────
  double timeOfDay    = 0.0;
  double flashTimer   = 0.0;
  double shakeMagnitude = 0.0;  // screen shake intensity

  static const double _flashDuration = 0.25;
  static const double _shakeDuration = 0.35;

  // ── World ─────────────────────────────────────────────────
  double groundY    = 300;
  double gameSpeed  = 250;
  Size canvasSize   = Size.zero;

  static const double _stepInterval = 0.15;

  // ── Expose particle + milestone data to painter ────────────
  List<Particle> get particles => _particles.particles;
  bool get isCelebrating       => _milestones.isCelebrating;
  double get celebrationOpacity => _milestones.celebrationOpacity;
  int get celebrationScore     => _milestones.celebrationScore;

  // ── Init ──────────────────────────────────────────────────

  void initialize(Size size) {
    canvasSize = size;
    groundY = size.height * 0.75;
    ground = Ground();
    _resetDino();
    _spawnInitialClouds();
  }

  void _resetDino() {
    dino = Dino(x: canvasSize.width * 0.15, y: groundY - 60);
  }

  void _spawnInitialClouds() {
    clouds.clear();
    for (int i = 0; i < 4; i++) {
      clouds.add(_makeCloud(x: _random.nextDouble() * canvasSize.width));
    }
  }

  Clouds _makeCloud({double? x}) => Clouds(
        X: x ?? canvasSize.width + 50,
        Y: 40 + _random.nextDouble() * (groundY * 0.4),
        width: 60 + _random.nextDouble() * 80,
        opacity: 0.4 + _random.nextDouble() * 0.5,
      );

  // ── Lifecycle ─────────────────────────────────────────────

  void startGame() {
    obstacles.clear();
    birds.clear();
    _particles.clear();
    score       = 0;
    gameSpeed   = 250;
    timeOfDay   = 0.0;
    flashTimer  = 0.0;
    shakeMagnitude = 0.0;
    _spawner.reset();
    _milestones.reset();
    _resetDino();
    ground = Ground();
    _spawnInitialClouds();
    gameState = GameState.playing;
  }

  // ── Input ─────────────────────────────────────────────────

  void handleTap() {
    if (gameState == GameState.playing) {
      _physics.jump(dino);
    } else {
      startGame();
    }
  }

  void handleDuckStart() {
    if (gameState == GameState.playing) {
      _physics.startDuck(dino);
    }
  }

  void handleDuckEnd() {
    if (gameState == GameState.playing) {
      _physics.endDuck(dino);
    }
  }

  // ── Update ────────────────────────────────────────────────

  void update(double dt) {
    // Effects tick even when game is over
    if (flashTimer > 0) flashTimer = (flashTimer - dt).clamp(0, _flashDuration);
    if (shakeMagnitude > 0) shakeMagnitude = (shakeMagnitude - dt * 2).clamp(0, 1.0);

    _particles.update(dt);

    if (gameState != GameState.playing) return;

    // 1. Physics + animation
    _physics.update(dino, groundY, dt);
    _updateDinoAnimation(dt);

    // 2. Day/night
    timeOfDay = (timeOfDay + dt / 120.0) % 1.0;

    // 3. Ground
    ground.scrollOffset += gameSpeed * dt;

    // 4. Obstacles
    for (final obs in obstacles) obs.x -= gameSpeed * dt;
    obstacles.removeWhere((o) => o.x + o.width < 0);

    // 5. Birds
    for (final bird in birds) {
      bird.x -= gameSpeed * 1.3 * dt;
      bird.flapTime += dt;
    }
    birds.removeWhere((b) => b.x + b.width < 0);

    // 6. Clouds
    for (final cloud in clouds) cloud.X -= gameSpeed * 0.2 * dt;
    clouds.removeWhere((c) => c.X + c.width < 0);
    if (clouds.length < 4 && _random.nextDouble() < 0.005) {
      clouds.add(_makeCloud());
    }

    // 7. Spawn
    final newObs = _spawner.updateObstacles(dt, canvasSize.width, groundY, score);
    if (newObs != null) obstacles.add(newObs);

    final newBird = _spawner.updateBirds(dt, canvasSize.width, groundY, score);
    if (newBird != null) birds.add(newBird);

    // 8. Collision
    if (_collision.checkCollision(dino, obstacles) || _checkBirdCollision()) {
      _onGameOver();
      return;
    }

    // 9. Score + speed
    score += (60 * dt).round();
    gameSpeed = 250 + score * 0.5;

    // 10. Milestones
    _milestones.update(score, dt);
  }

  bool _checkBirdCollision() {
    final dinoBounds = dino.activeBounds.deflate(6);
    for (final bird in birds) {
      if (dinoBounds.overlaps(bird.bounds)) return true;
    }
    return false;
  }

  void _updateDinoAnimation(double dt) {
    if (dino.isOnGround && !dino.isDucking) {
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
    flashTimer = _flashDuration;
    shakeMagnitude = 1.0;
    // Spawn explosion at dino center
    _particles.spawnExplosion(
      dino.x + dino.width / 2,
      dino.y + dino.height / 2,
    );
    gameState = GameState.gameOver;
  }
}*/



import 'dart:math';
import 'dart:ui';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../models/ground.dart';
import '../models/particle.dart';
import 'game_state.dart';
import 'storage_service.dart';

class GameController {
  // ── Entities ──────────────────────────────────────────────
  Dino dino           = Dino(x: 0, y: 0);
  List<Obstacle> obstacles = [];
  List<Bird> birds    = [];
  List<Clouds> clouds  = [];
  Ground ground       = Ground();

  // ── Systems ───────────────────────────────────────────────
  final _physics    = PhysicsSystem();
  final _collision  = CollisionSystem();
  final _spawner    = SpawnSystem();
  final _particles  = ParticleSystem();
  final _milestones = MilestoneSystem();
  final _random     = Random();

  // ── State ─────────────────────────────────────────────────
  GameState gameState = GameState.initial;
  int score     = 0;
  int highScore = 0;

  // ── Effects ───────────────────────────────────────────────
  double timeOfDay      = 0.0;
  double flashTimer     = 0.0;
  double shakeMagnitude = 0.0;

  /// Elapsed time since app start — drives title bob animation.
  double totalTime = 0.0;

  static const double _flashDuration = 0.25;

  // ── World ─────────────────────────────────────────────────
  double groundY   = 300;
  double gameSpeed = 250;
  Size canvasSize  = Size.zero;

  static const double _stepInterval = 0.15;

  // ── Expose effect data ─────────────────────────────────────
  List<Particle> get particles        => _particles.particles;
  bool get isCelebrating              => _milestones.isCelebrating;
  double get celebrationOpacity       => _milestones.celebrationOpacity;
  int get celebrationScore            => _milestones.celebrationScore;

  // ── Init ──────────────────────────────────────────────────

  Future<void> initialize(Size size) async {
    canvasSize = size;
    groundY    = size.height * 0.75;
    ground     = Ground();
    _resetDino();
    _spawnInitialClouds();

    // Load persisted high score from device storage
    highScore = await StorageService.loadHighScore();
  }

  void _resetDino() {
    dino = Dino(x: canvasSize.width * 0.15, y: groundY - 60);
  }

  void _spawnInitialClouds() {
    clouds.clear();
    for (int i = 0; i < 4; i++) {
      clouds.add(_makeCloud(x: _random.nextDouble() * canvasSize.width));
    }
  }

  Clouds _makeCloud({double? x}) => Clouds(
        X: x ?? canvasSize.width + 50,
        Y: 40 + _random.nextDouble() * (groundY * 0.4),
        width: 60 + _random.nextDouble() * 80,
        opacity: 0.4 + _random.nextDouble() * 0.5,
      );

  // ── Lifecycle ─────────────────────────────────────────────

  void startGame() {
    obstacles.clear();
    birds.clear();
    _particles.clear();
    score         = 0;
    gameSpeed     = 250;
    timeOfDay     = 0.0;
    flashTimer    = 0.0;
    shakeMagnitude = 0.0;
    _spawner.reset();
    _milestones.reset();
    _resetDino();
    ground = Ground();
    _spawnInitialClouds();
    gameState = GameState.playing;
  }

  // ── Input ─────────────────────────────────────────────────

  void handleTap() {
    if (gameState == GameState.playing) {
      _physics.jump(dino);
    } else {
      startGame();
    }
  }

  void handleDuckStart() {
    if (gameState == GameState.playing) _physics.startDuck(dino);
  }

  void handleDuckEnd() {
    if (gameState == GameState.playing) _physics.endDuck(dino);
  }

  // ── Update ────────────────────────────────────────────────

  void update(double dt) {
    totalTime += dt; // always tick — drives title animation

    if (flashTimer > 0) flashTimer = (flashTimer - dt).clamp(0, _flashDuration);
    if (shakeMagnitude > 0) shakeMagnitude = (shakeMagnitude - dt * 2).clamp(0, 1.0);

    _particles.update(dt);

    if (gameState != GameState.playing) return;

    _physics.update(dino, groundY, dt);
    _updateDinoAnimation(dt);

    timeOfDay = (timeOfDay + dt / 120.0) % 1.0;
    ground.scrollOffset += gameSpeed * dt;

    for (final obs in obstacles) obs.x -= gameSpeed * dt;
    obstacles.removeWhere((o) => o.x + o.width < 0);

    for (final bird in birds) {
      bird.x -= gameSpeed * 1.3 * dt;
      bird.flapTime += dt;
    }
    birds.removeWhere((b) => b.x + b.width < 0);

    for (final cloud in clouds) cloud.X -= gameSpeed * 0.2 * dt;
    clouds.removeWhere((c) => c.X + c.width < 0);
    if (clouds.length < 4 && _random.nextDouble() < 0.005) {
      clouds.add(_makeCloud());
    }

    final newObs = _spawner.updateObstacles(dt, canvasSize.width, groundY, score);
    if (newObs != null) obstacles.add(newObs);

    final newBird = _spawner.updateBirds(dt, canvasSize.width, groundY, score);
    if (newBird != null) birds.add(newBird);

    if (_collision.checkCollision(dino, obstacles) || _checkBirdCollision()) {
      _onGameOver();
      return;
    }

    score += (60 * dt).round();
    gameSpeed = 250 + score * 0.5;
    _milestones.update(score, dt);
  }

  bool _checkBirdCollision() {
    final dinoBounds = dino.activeBounds.deflate(6);
    for (final bird in birds) {
      if (dinoBounds.overlaps(bird.bounds)) return true;
    }
    return false;
  }

  void _updateDinoAnimation(double dt) {
    if (dino.isOnGround && !dino.isDucking) {
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

  Future<void> _onGameOver() async {
    if (score > highScore) {
      highScore = score;
      // Persist the new high score immediately
      await StorageService.saveHighScore(highScore);
    }
    flashTimer    = _flashDuration;
    shakeMagnitude = 1.0;
    _particles.spawnExplosion(
      dino.x + dino.width / 2,
      dino.y + dino.height / 2,
    );
    gameState = GameState.gameOver;
  }
}