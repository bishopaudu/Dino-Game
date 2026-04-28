import 'package:flutter/scheduler.dart';
import 'game_controller.dart';

/// Drives the game forward by calling update() on every animation frame.
/// 
/// Uses Flutter's [Ticker] to hook into the vsync signal — the same
/// signal that powers AnimationController. This guarantees our loop
/// runs in sync with the display refresh rate.
class GameLoop {
  final GameController _controller;
  late Ticker _ticker;

  /// Timestamp of the previous frame, used to compute delta time.
  Duration _lastElapsed = Duration.zero;

  GameLoop(this._controller, TickerProvider vsync) {
    // Create a Ticker that fires on every vsync.
    _ticker = vsync.createTicker(_onTick);
  }

  /// Called by Flutter on every frame.
  /// [elapsed] is the total time since the ticker started.
  void _onTick(Duration elapsed) {
    // Delta time: how long since the last frame (in seconds).
    // If the app was paused, dt could be large — clamp it to avoid
    // objects teleporting across the screen after a resume.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    _controller.update(dt);
  }

  void start() {
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
  }

  void dispose() {
    _ticker.dispose();
  }
}