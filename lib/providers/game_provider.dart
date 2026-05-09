/*import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/game_controller.dart';
import '../core/game_loop.dart';
import '../core/game_state.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';

/// Provider that bridges the game engine and the Flutter widget tree.
/// 
/// Why ChangeNotifier + notifyListeners?
/// The game loop updates 60x/second. Rather than rebuilding the entire
/// widget tree that fast, we let CustomPainter decide when to repaint
/// by listening directly to this notifier. Only the canvas repaints —
/// not the score text, not buttons, etc.
class GameProvider extends ChangeNotifier {
  late GameController _controller;
  late GameLoop _loop;
  Ticker? _notifyTicker;
  bool isInitialized = false;

  // ── Read-only accessors for the UI ─────────────────────────

  GameState get gameState => _controller.gameState;
  int get score => _controller.score;
  Dino get dino => _controller.dino;
  List<Obstacle> get obstacles => _controller.obstacles;
  double get groundY => _controller.groundY;

  // ── Initialization ─────────────────────────────────────────

  /// Must be called once from the game canvas widget after layout.
  void initialize(Size size, TickerProvider vsync) {
        if (isInitialized) return;
    _controller = GameController();
    _controller.initialize(size);
    _loop = GameLoop(_controller, vsync);
    _loop.start();

    // After each frame tick, notify the UI to repaint the canvas.
    // This is the connection: game loop → ChangeNotifier → CustomPainter.
    _controller; // ensure controller exists before we begin
    _startNotifying(vsync);
    _notifyTicker = vsync.createTicker((_) {
      notifyListeners(); // triggers CustomPainter repaint each frame
    });
    _notifyTicker!.start();

    isInitialized = true;
  }

  void _startNotifying(TickerProvider vsync) {
    // Use a second ticker just to call notifyListeners each frame.
    // This triggers the CustomPainter's repaint.
    vsync.createTicker((_) {
      notifyListeners();
    }).start();
  }

  // ── Actions ────────────────────────────────────────────────


  void onTap() {
    // Silently ignore taps before initialization completes.
    if (!isInitialized) return;
    _controller!.handleTap();
  }


  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }
}*/

import 'dart:ui';
import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/models/ground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/game_controller.dart';
import '../core/game_loop.dart';
import '../core/game_state.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';

class GameProvider extends ChangeNotifier {
  GameController? _controller;  // nullable — NOT late
  GameLoop? _loop;
  Ticker? _notifyTicker;        // only ONE ticker total
  bool isInitialized = false;

  // Safe accessors — return fallback values until initialized
  GameState get gameState => _controller?.gameState ?? GameState.initial;
  int get score => _controller?.score ?? 0;
  Dino? get dino => _controller?.dino;           // nullable — canvas checks before use
  List<Obstacle> get obstacles => _controller?.obstacles ?? [];
  double get groundY => _controller?.groundY ?? 300;
    List<Clouds> get clouds => _controller?.clouds ?? [];
  //Ground? get ground => _controller?.ground;
  Ground get ground => _controller?.ground ?? Ground();

    int get highScore => _controller?.highScore ?? 0;


  void initialize(Size size, TickerProvider vsync) {
    if (isInitialized) return;  // guard against double-init

    _controller = GameController();
    _controller!.initialize(size);

    _loop = GameLoop(_controller!, vsync);
    _loop!.start();

    // ONE ticker only — drives both the game loop notify and repaint
    _notifyTicker = vsync.createTicker((_) {
      notifyListeners();
    });
    _notifyTicker!.start();

    isInitialized = true;
    notifyListeners(); // tell UI we're ready
  }

  void onTap() {
    if (!isInitialized || _controller == null) return;
    _controller!.handleTap();
  }

  @override
  void dispose() {
    _loop?.dispose();
    _notifyTicker?.dispose();
    super.dispose();
  }
}