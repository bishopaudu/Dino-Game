import 'dart:math';
import 'package:dino_game/core/audio_service.dart';
import 'package:dino_game/core/haptic_service.dart';
import 'package:dino_game/core/storage_service.dart';
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
/// Responsibilities:
/// - Holds references to all game objects (dino, obstacles)
/// - Coordinates systems (physics, collision, spawning)
/// - Runs the update loop
/// - Manages game state transitions
/// - Exposes state for the UI to read


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

  // ── Services ──────────────────────────────────────────────
  final _audio    = AudioService();
  final _haptics  = HapticService();
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

  // Score tick — plays a soft sound every 100 points
  int _lastPointSound = 0;

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

  /*void handleTap() {
    if (gameState == GameState.playing) {
      _physics.jump(dino);
    } else {
      startGame();
    }
  }*/
    void handleTap() {
    switch (gameState) {
      case GameState.playing:
        _physics.jump(dino);
        _audio.playJump();
        _haptics.lightTap();
      case GameState.paused:
        // Tap while paused does nothing — use the resume button
        break;
      default:
        startGame();
    }
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
    }
    _audio.playButton();
    _haptics.lightTap();
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

    for (final obs in obstacles) {
      obs.x -= gameSpeed * dt;
    }
    obstacles.removeWhere((o) => o.x + o.width < 0);

    for (final bird in birds) {
      bird.x -= gameSpeed * 1.3 * dt;
      bird.flapTime += dt;
    }
    birds.removeWhere((b) => b.x + b.width < 0);

    for (final cloud in clouds) {
      cloud.X -= gameSpeed * 0.2 * dt;
    }
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
    if (score ~/ 100 > _lastPointSound) {
      _lastPointSound = score ~/ 100;
      _audio.playPoint();
    }

    // Milestones
    final hitMilestone = _milestones.update(score, dt);
    if (hitMilestone) {
      _audio.playMilestone();
      _haptics.mediumTap();
    }
    
    //_milestones.update(score, dt);
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
    _audio.playDie();
    _haptics.heavyImpact();

    if (score > highScore) {
      highScore = score;
      await StorageService.saveHighScore(highScore);
    }

    await StorageService.incrementGamesPlayed();
    await StorageService.addToTotalScore(score);

    flashTimer     = _flashDuration;
    shakeMagnitude = 1.0;
    _particles.spawnExplosion(
      dino.x + dino.width / 2,
      dino.y + dino.height / 2,
    );
    gameState = GameState.gameOver;
  }
}