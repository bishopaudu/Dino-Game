/// Provider that bridges the game engine and the Flutter widget tree. 
/// Why ChangeNotifier + notifyListeners?
/// The game loop updates 60x/second. Rather than rebuilding the entire
/// widget tree that fast, we let CustomPainter decide when to repaint
/// by listening directly to this notifier. Only the canvas repaints —
/// not the score text, not buttons, etc.
library;


import 'package:dino_game/core/sprite_loader.dart';
import 'package:dino_game/models/birds.dart';
import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/models/particle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/game_controller.dart';
import '../core/game_loop.dart';
import '../core/game_state.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../models/ground.dart';

class GameProvider extends ChangeNotifier {
  GameController? _controller;
  GameLoop? _loop;
  Ticker? _notifyTicker;
  bool isInitialized = false;
  // Sprites loaded once at startup
  GameSprites sprites = GameSprites.empty;
  bool spritesLoaded  = false;
  GameState get gameState   => _controller?.gameState ?? GameState.initial;
  int get score             => _controller?.score ?? 0;
  int get highScore         => _controller?.highScore ?? 0;
  Dino? get dino            => _controller?.dino;
  List<Obstacle> get obstacles => _controller?.obstacles ?? [];
  List<Bird> get birds      => _controller?.birds ?? [];
  List<Clouds> get clouds    => _controller?.clouds ?? [];
  Ground get ground         => _controller?.ground ?? Ground();
  double get groundY        => _controller?.groundY ?? 300;
  double get timeOfDay      => _controller?.timeOfDay ?? 0.0;
  double get flashTimer     => _controller?.flashTimer ?? 0.0;
   double get shakeMagnitude       => _controller?.shakeMagnitude ?? 0.0;
  List<Particle> get particles    => _controller?.particles ?? [];
  bool get isCelebrating          => _controller?.isCelebrating ?? false;
  double get celebrationOpacity   => _controller?.celebrationOpacity ?? 0.0;
  int get celebrationScore        => _controller?.celebrationScore ?? 0;
    double get totalTime             => _controller?.totalTime ?? 0.0;


  Future<void> initialize(Size size, TickerProvider vsync) async {
    if (isInitialized) return;

    // Load sprites in parallel with controller init
    final results = await Future.wait([
      _initController(size),
      SpriteLoader.load(),
    ]);

    sprites      = results[1] as GameSprites;
    spritesLoaded = true;

    _loop = GameLoop(_controller!, vsync);
    _loop!.start();

    _notifyTicker = vsync.createTicker((_) => notifyListeners());
    _notifyTicker!.start();

    isInitialized = true;
    notifyListeners();
  }

  /*void initialize(Size size, TickerProvider vsync) {
    if (isInitialized) return;
    _controller = GameController();
    _controller!.initialize(size);
    _loop = GameLoop(_controller!, vsync);
    _loop!.start();
    _notifyTicker = vsync.createTicker((_) => notifyListeners());
    _notifyTicker!.start();
    isInitialized = true;
    notifyListeners();
  }*/
   Future<GameController> _initController(Size size) async {
    _controller = GameController();
    await _controller!.initialize(size);
    return _controller!;
  }

  void onTap() {
    if (!isInitialized || _controller == null) return;
    _controller!.handleTap();
  }

    void onDuckStart()  { if (!isInitialized) return; _controller!.handleDuckStart(); }
  void onDuckEnd()    { if (!isInitialized) return; _controller!.handleDuckEnd(); }

  @override
  void dispose() {
    _loop?.dispose();
    _notifyTicker?.dispose();
    super.dispose();
  }
}