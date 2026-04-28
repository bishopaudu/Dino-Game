import 'package:flutter/material.dart';
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

  // ── Read-only accessors for the UI ─────────────────────────

  GameState get gameState => _controller.gameState;
  int get score => _controller.score;
  Dino get dino => _controller.dino;
  List<Obstacle> get obstacles => _controller.obstacles;
  double get groundY => _controller.groundY;

  // ── Initialization ─────────────────────────────────────────

  /// Must be called once from the game canvas widget after layout.
  void initialize(Size size, TickerProvider vsync) {
    _controller = GameController();
    _controller.initialize(size);
    _loop = GameLoop(_controller, vsync);
    _loop.start();

    // After each frame tick, notify the UI to repaint the canvas.
    // This is the connection: game loop → ChangeNotifier → CustomPainter.
    _controller; // ensure controller exists before we begin
    _startNotifying(vsync);
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
    _controller.handleTap();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }
}