import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../core/game_state.dart';

/// Renders the entire game scene using Flutter's Canvas API.
/// 
/// CustomPainter.paint() is called every frame (when shouldRepaint
/// returns true). We receive a Canvas — our drawing surface — and
/// a Size — the available space.
/// 
/// Canvas coordinate system:
///   (0,0) is TOP-LEFT
///   X increases rightward
///   Y increases DOWNWARD
///   All units are logical pixels
class GamePainter extends CustomPainter {
  final Dino dino;
  final List<Obstacle> obstacles;
  final double groundY;
  final GameState gameState;
  final int score;

  // Pre-allocated Paint objects.
  // IMPORTANT: Never allocate Paint inside paint() — it runs 60x/second.
  // Creating objects in a hot loop causes garbage collection stutters.
  final Paint _dinoPaint = Paint()..color = const Color(0xFF4A4A4A);
  final Paint _obstaclePaint = Paint()..color = const Color(0xFF2D7A2D);
  final Paint _groundPaint = Paint()
    ..color = const Color(0xFF8B7355)
    ..strokeWidth = 2;
  final Paint _skyPaint = Paint()..color = const Color(0xFFF5F5F5);

  GamePainter({
    required this.dino,
    required this.obstacles,
    required this.groundY,
    required this.gameState,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw sky background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _skyPaint);

    // 2. Draw ground line
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      _groundPaint,
    );

    // 3. Draw dino (a simple rectangle for now)
    canvas.drawRRect(
      RRect.fromRectAndRadius(dino.bounds, const Radius.circular(4)),
      _dinoPaint,
    );

    // 4. Draw all obstacles
    for (final obstacle in obstacles) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(obstacle.bounds, const Radius.circular(3)),
        _obstaclePaint,
      );
    }

    // 5. Draw score
    _drawScore(canvas, size);

    // 6. Draw game state overlays
    if (gameState == GameState.initial) {
      _drawCenteredText(canvas, size, 'Tap to start', 28);
    } else if (gameState == GameState.gameOver) {
      _drawCenteredText(canvas, size, 'Game Over!', 36);
      _drawCenteredText(canvas, size, 'Tap to restart', 22, offsetY: 50);
    }
  }

  void _drawScore(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Score: $score',
        style: const TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    // Draw in top-right corner
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 16, 16));
  }

  void _drawCenteredText(Canvas canvas, Size size, String text, double fontSize,
      {double offsetY = 0}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF4A4A4A),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height / 2 - textPainter.height / 2 + offsetY,
      ),
    );
  }

  /// shouldRepaint tells Flutter whether to call paint() this frame.
  /// Return true always for a game — we update every frame.
  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}