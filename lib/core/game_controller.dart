/*import 'dart:math';
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
}*/


import 'dart:math';
import 'dart:ui';
import 'package:dino_game/models/birds.dart';
import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/models/run_model.dart';
import 'package:dino_game/system/achievments_system.dart';
import 'package:dino_game/system/collision_system.dart';
import 'package:dino_game/system/milestone_system.dart';
import 'package:dino_game/system/partilce_system.dart';
import 'package:dino_game/system/physics_system.dart';
import 'package:dino_game/system/spawn_system.dart';

import '../models/dino.dart';
import '../models/obstacle.dart';
  import '../models/clouds.dart';
import '../models/ground.dart';
import '../models/particle.dart';
import '../models/achievement.dart';
import '../models/dino_skin.dart';
import 'game_state.dart';
import 'storage_service.dart';
import 'audio_service.dart';
import 'haptic_service.dart';

class GameController {
  // ── Entities ──────────────────────────────────────────────
  Dino dino           = Dino(x: 0, y: 0);
  List<Obstacle> obstacles = [];
  List<Bird> birds    = [];
  List<Clouds> clouds  = [];
  Ground ground       = Ground();

  // ── Services ──────────────────────────────────────────────
  final _audio   = AudioService();
  final _haptics = HapticService();

  // ── Systems ───────────────────────────────────────────────
  final _physics       = PhysicsSystem();
  final _collision     = CollisionSystem();
  final _spawner       = SpawnSystem();
  final _particles     = ParticleSystem();
  final _milestones    = MilestoneSystem();
  final _achievements  = AchievementSystem();
  final _random        = Random();

  // ── State ─────────────────────────────────────────────────
  GameState gameState = GameState.initial;
  int score     = 0;
  int highScore = 0;

  // ── Skin system ───────────────────────────────────────────
  DinoSkin activeSkin     = DinoSkins.all.first;
  Set<String> unlockedSkinIds = {'classic'};
  List<Achievement> achievements = [];

  // ── Run tracking ──────────────────────────────────────────
  double _runStartTime  = 0.0;  // totalTime when current run started
  int _lastPointSound   = 0;

  // ── Newly unlocked (shown as banners) ─────────────────────
  final List<Achievement> pendingUnlocks = [];

  // ── Effects ───────────────────────────────────────────────
  double timeOfDay      = 0.0;
  double flashTimer     = 0.0;
  double shakeMagnitude = 0.0;
  double totalTime      = 0.0;

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
  int get survivalSeconds             => (totalTime - _runStartTime).round();

  // ── Init ──────────────────────────────────────────────────

  Future<void> initialize(Size size) async {

    // Add after loading unlockedSkinIds:
//unlockedSkinIds.addAll(['ghost', 'robot', 'lava', 'shadow']); // temp
    canvasSize = size;
    groundY    = size.height * 0.75;
    ground     = Ground();

    // Load all persisted data in parallel
    final results = await Future.wait([
      StorageService.loadHighScore(),
      StorageService.loadAchievements(),
      StorageService.loadSelectedSkin(),
      StorageService.loadUnlockedSkins(),
    ]);

    highScore         = results[0] as int;
    achievements      = results[1] as List<Achievement>;
    final skinId      = results[2] as String;
    unlockedSkinIds   = results[3] as Set<String>;
    activeSkin        = DinoSkins.getById(skinId);

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
    pendingUnlocks.clear();
    score          = 0;
    gameSpeed      = 250;
    timeOfDay      = 0.0;
    flashTimer     = 0.0;
    shakeMagnitude = 0.0;
    _lastPointSound = 0;
    _runStartTime  = totalTime;
    _spawner.reset();
    _milestones.reset();
    _resetDino();
    ground = Ground();
    _spawnInitialClouds();
    gameState = GameState.playing;
  }

  // ── Skin management ───────────────────────────────────────

  Future<void> selectSkin(DinoSkin skin) async {
    if (!unlockedSkinIds.contains(skin.id)) return;
    activeSkin = skin;
    await StorageService.saveSelectedSkin(skin.id);
  }

  /// Checks if a skin should be unlocked based on all-time high score.
  Future<void> _checkSkinUnlocks() async {
    bool changed = false;
    for (final skin in DinoSkins.all) {
      if (!unlockedSkinIds.contains(skin.id) &&
          highScore >= skin.unlockScore) {
        unlockedSkinIds.add(skin.id);
        changed = true;
      }
    }
    if (changed) {
      await StorageService.saveUnlockedSkins(unlockedSkinIds);
    }
  }

  // ── Input ─────────────────────────────────────────────────

  void handleTap() {
    switch (gameState) {
      case GameState.playing:
        _physics.jump(dino);
        _audio.playJump();
        _haptics.lightTap();
      case GameState.paused:
        break;
      default:
        startGame();
    }
  }

  void handleDuckStart() {
    if (gameState == GameState.playing) _physics.startDuck(dino);
  }

  void handleDuckEnd() {
    if (gameState == GameState.playing) _physics.endDuck(dino);
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

  // ── Update ────────────────────────────────────────────────

  void update(double dt) {
    totalTime += dt;

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

    final newObs = _spawner.updateObstacles(
        dt, canvasSize.width, groundY, score);
    if (newObs != null) obstacles.add(newObs);

    final newBird = _spawner.updateBirds(
        dt, canvasSize.width, groundY, score);
    if (newBird != null) birds.add(newBird);

    if (_collision.checkCollision(dino, obstacles) ||
        _checkBirdCollision()) {
      _onGameOver();
      return;
    }

    score += (60 * dt).round();
    gameSpeed = 250 + score * 0.5;

    if (score ~/ 100 > _lastPointSound) {
      _lastPointSound = score ~/ 100;
      _audio.playPoint();
    }

    final hitMilestone = _milestones.update(score, dt);
    if (hitMilestone) {
      _audio.playMilestone();
      _haptics.mediumTap();
    }

    // Check survival achievements during gameplay
    _evaluateAchievements();
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

  void _evaluateAchievements() {
    final totalGames = 0; // loaded async — evaluated properly on game over
    final newUnlocks = _achievements.evaluate(
      current:         achievements,
      score:           score,
      totalGames:      totalGames,
      survivalSeconds: survivalSeconds,
      timeOfDay:       timeOfDay,
    );

    if (newUnlocks.isNotEmpty) {
      pendingUnlocks.addAll(newUnlocks);
      StorageService.saveAchievements(achievements);
      _audio.playMilestone();
      _haptics.mediumTap();
    }
  }

  Future<void> _onGameOver() async {
    _audio.playDie();
    _haptics.heavyImpact();

    if (score > highScore) {
      highScore = score;
      await StorageService.saveHighScore(highScore);
    }

    final totalGames = await StorageService.loadTotalGamesPlayed();
    await StorageService.incrementGamesPlayed();
    await StorageService.addToTotalScore(score);

    // Final achievement evaluation with accurate totalGames
    final newUnlocks = _achievements.evaluate(
      current:         achievements,
      score:           score,
      totalGames:      totalGames + 1,
      survivalSeconds: survivalSeconds,
      timeOfDay:       timeOfDay,
    );

    if (newUnlocks.isNotEmpty) {
      pendingUnlocks.addAll(newUnlocks);
      await StorageService.saveAchievements(achievements);
    }

    // Save run record
    await StorageService.addRunRecord(RunRecord(
      score:           score,
      playedAt:        DateTime.now(),
      skinId:          activeSkin.id,
      durationSeconds: survivalSeconds,
    ));

    // Check if any new skins unlocked
    await _checkSkinUnlocks();

    flashTimer     = _flashDuration;
    shakeMagnitude = 1.0;
    _particles.spawnExplosion(
      dino.x + dino.width / 2,
      dino.y + dino.height / 2,
    );
    gameState = GameState.gameOver;
  }
}