import 'package:dino_game/models/clouds.dart';
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
/*class GamePainter extends CustomPainter {
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
}*/

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../models/clouds.dart';
import '../models/ground.dart';
import '../core/game_state.dart';

class GamePainter extends CustomPainter {
  final Dino dino;
  final List<Obstacle> obstacles;
  final List<Clouds> clouds;
  final Ground ground;
  final double groundY;
  final GameState gameState;
  final int score;
  final int highScore;

  // ── Pre-allocated paints (never allocate inside paint()) ──
  final Paint _skyPaint = Paint()..color = const Color(0xFFF7F7F7);
  final Paint _groundPaint = Paint()
    ..color = const Color(0xFF9E8B70)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final Paint _groundTickPaint = Paint()
    ..color = const Color(0xFFB8A898)
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  final Paint _dinoPaint = Paint()..color = const Color(0xFF555555);
  final Paint _dinoEyePaint = Paint()..color = const Color(0xFFF7F7F7);
  final Paint _dinoLegPaint = Paint()..color = const Color(0xFF444444);
  final Paint _obstaclePaint = Paint()..color = const Color(0xFF3A8A3A);
  final Paint _obstacleDarkPaint = Paint()..color = const Color(0xFF2D6B2D);
  final Paint _cloudPaint = Paint()..color = const Color(0xFFDDDDDD);

  // Ground tile spacing in pixels
  static const double _tileWidth = 60;

  GamePainter({
    required this.dino,
    required this.obstacles,
    required this.clouds,
    required this.ground,
    required this.groundY,
    required this.gameState,
    required this.score,
    required this.highScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawClouds(canvas);
    _drawGround(canvas, size);
    _drawObstacles(canvas);
    _drawDino(canvas);
    _drawHUD(canvas, size);

    if (gameState == GameState.initial) {
      _drawOverlay(canvas, size, 'Tap to start', null);
    } else if (gameState == GameState.gameOver) {
      _drawOverlay(canvas, size, 'Game Over', 'Tap to restart');
    }
  }

  // ── Sky ────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _skyPaint);
  }

  // ── Clouds ─────────────────────────────────────────────────

  void _drawCloud(Canvas canvas, Clouds cloud) {
    _cloudPaint.color = Color.fromRGBO(200, 200, 200, cloud.opacity);

    final cx = cloud.X + cloud.width / 2;
    final cy = cloud.Y;
    final r = cloud.width / 4;

    // Draw a cloud as overlapping circles
    canvas.drawCircle(Offset(cx, cy), r, _cloudPaint);
    canvas.drawCircle(Offset(cx - r * 0.8, cy + r * 0.3), r * 0.7, _cloudPaint);
    canvas.drawCircle(Offset(cx + r * 0.8, cy + r * 0.3), r * 0.7, _cloudPaint);
    canvas.drawCircle(Offset(cx - r * 1.4, cy + r * 0.6), r * 0.55, _cloudPaint);
    canvas.drawCircle(Offset(cx + r * 1.4, cy + r * 0.6), r * 0.55, _cloudPaint);
  }

  void _drawClouds(Canvas canvas) {
    for (final cloud in clouds) {
      _drawCloud(canvas, cloud);
    }
  }

  // ── Ground ─────────────────────────────────────────────────

  void _drawGround(Canvas canvas, Size size) {
    // Main ground line
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      _groundPaint,
    );

    // Second thinner line just below for depth
    _groundTickPaint.strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, groundY + 4),
      Offset(size.width, groundY + 4),
      _groundTickPaint,
    );

    // Scrolling tick marks — the modulo trick for infinite ground.
    // offset % tileWidth gives a value that wraps smoothly 0→tileWidth→0.
    final scrollX = ground.scrollOffset % _tileWidth;

    for (double x = -scrollX; x < size.width; x += _tileWidth) {
      // Small tick below the ground line
      canvas.drawLine(
        Offset(x, groundY + 2),
        Offset(x + 12, groundY + 2),
        _groundTickPaint,
      );
    }
  }

  // ── Dino ───────────────────────────────────────────────────

  void _drawDino(Canvas canvas) {
    final x = dino.x;
    final y = dino.y;
    final w = dino.width;
    final h = dino.height;

    // Body — main rounded rectangle
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, w, h * 0.7),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(14), // rounded head end
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      _dinoPaint,
    );

    // Head bump — a slightly raised area on the right side
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.55, y - h * 0.12, w * 0.45, h * 0.3),
        const Radius.circular(8),
      ),
      _dinoPaint,
    );

    // Eye — white circle
    canvas.drawCircle(
      Offset(x + w * 0.82, y - h * 0.02),
      4,
      _dinoEyePaint,
    );

    // Pupil — small dark dot
    canvas.drawCircle(
      Offset(x + w * 0.85, y - h * 0.02),
      2,
      _dinoLegPaint,
    );

    // Legs — alternate based on animation state
    _drawLegs(canvas, x, y, w, h);
  }

  void _drawLegs(Canvas canvas, double x, double y, double w, double h) {
    final legY = y + h * 0.68; // top of legs
    final legHeight = h * 0.32;
    final legWidth = w * 0.18;
    final leftLegX = x + w * 0.25;
    final rightLegX = x + w * 0.55;

    if (dino.isOnGround) {
      // Alternating run cycle: one leg up, one leg down
      final leftOffset = dino.leftLegUp ? -legHeight * 0.35 : 0.0;
      final rightOffset = dino.leftLegUp ? 0.0 : -legHeight * 0.35;

      // Left leg
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftLegX, legY + leftOffset, legWidth, legHeight),
          const Radius.circular(3),
        ),
        _dinoLegPaint,
      );

      // Right leg
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rightLegX, legY + rightOffset, legWidth, legHeight),
          const Radius.circular(3),
        ),
        _dinoLegPaint,
      );
    } else {
      // Airborne: both legs tucked slightly back
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftLegX - 4, legY - legHeight * 0.1, legWidth, legHeight * 0.85),
          const Radius.circular(3),
        ),
        _dinoLegPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rightLegX - 4, legY, legWidth, legHeight * 0.85),
          const Radius.circular(3),
        ),
        _dinoLegPaint,
      );
    }
  }

  // ── Obstacles ──────────────────────────────────────────────

  void _drawObstacles(Canvas canvas) {
    for (final obs in obstacles) {
      _drawCactus(canvas, obs);
    }
  }

  void _drawCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x;
    final y = obs.y;
    final w = obs.width;
    final h = obs.height;

    // Main trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.3, y, w * 0.4, h),
        const Radius.circular(3),
      ),
      _obstaclePaint,
    );

    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + h * 0.3, w * 0.35, h * 0.15),
        const Radius.circular(3),
      ),
      _obstaclePaint,
    );
    // Left arm vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + h * 0.15, w * 0.32, h * 0.3),
        const Radius.circular(3),
      ),
      _obstaclePaint,
    );

    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.65, y + h * 0.35, w * 0.35, h * 0.15),
        const Radius.circular(3),
      ),
      _obstaclePaint,
    );
    // Right arm vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.68, y + h * 0.2, w * 0.32, h * 0.3),
        const Radius.circular(3),
      ),
      _obstaclePaint,
    );

    // Dark edge on trunk for depth
    _obstacleDarkPaint.strokeWidth = 2;
    canvas.drawLine(
      Offset(x + w * 0.3, y),
      Offset(x + w * 0.3, y + h),
      _obstacleDarkPaint,
    );
  }

  // ── HUD ────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    // Current score — top right
    _drawText(
      canvas,
      'Score: ${score.toString().padLeft(5, '0')}',
      Offset(size.width - 160, 20),
      fontSize: 18,
      color: const Color(0xFF555555),
      fontWeight: FontWeight.bold,
    );

    // High score — next to score
    if (highScore > 0) {
      _drawText(
        canvas,
        'HI: ${highScore.toString().padLeft(5, '0')}',
        Offset(size.width - 310, 20),
        fontSize: 18,
        color: const Color(0xFF999999),
        fontWeight: FontWeight.bold,
      );
    }
  }

  // ── Overlays ───────────────────────────────────────────────

  void _drawOverlay(Canvas canvas, Size size, String title, String? subtitle) {
    // Dim background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0x44000000),
    );

    final centerY = size.height / 2;

    _drawText(
      canvas,
      title,
      Offset(0, centerY - 40),
      fontSize: 40,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
      width: size.width,
    );

    if (subtitle != null) {
      _drawText(
        canvas,
        subtitle,
        Offset(0, centerY + 20),
        fontSize: 22,
        color: Colors.white70,
        textAlign: TextAlign.center,
        width: size.width,
      );
    }

    if (gameState == GameState.gameOver && highScore > 0) {
      _drawText(
        canvas,
        'Best: $highScore',
        Offset(0, centerY + 60),
        fontSize: 18,
        color: Colors.white60,
        textAlign: TextAlign.center,
        width: size.width,
      );
    }
  }

  // ── Text helper ────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 16,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
    double? width,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    painter.layout(maxWidth: width ?? double.infinity);

    final dx = textAlign == TextAlign.center
        ? position.dx + ((width ?? 0) - painter.width) / 2
        : position.dx;

    painter.paint(canvas, Offset(dx, position.dy));
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}