import 'package:dino_game/models/clouds.dart';
import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../core/game_state.dart';
import '../models/ground.dart';
import '../models/birds.dart';


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
import '../models/ground.dart';
import '../core/game_state.dart';

class GamePainter extends CustomPainter {
  final Dino dino;
  final List<Obstacle> obstacles;
  final List<Bird> birds;
  final List<Clouds> clouds;
  final Ground ground;
  final double groundY;
  final GameState gameState;
  final int score;
  final int highScore;
  final double timeOfDay;   // 0.0=day, 1.0=night
  final double flashTimer;  // >0 means flash is active

  // ── Day/night color pairs ──────────────────────────────────
  static const _daySky        = Color(0xFFF7F7F7);
  static const _nightSky      = Color(0xFF1A1A2E);
  static const _dayGround     = Color(0xFF9E8B70);
  static const _nightGround   = Color(0xFF4A4060);
  static const _dayGroundTick = Color(0xFFB8A898);
  static const _nightGroundTick = Color(0xFF6A5A80);
  static const _dayDino       = Color(0xFF555555);
  static const _nightDino     = Color(0xFF8888BB);
  static const _dayCactus     = Color(0xFF3A8A3A);
  static const _nightCactus   = Color(0xFF2A6A5A);
  static const _dayBird       = Color(0xFF666666);
  static const _nightBird     = Color(0xFF9999CC);
  static const _dayCloud      = Color(0xFFDDDDDD);
  static const _nightCloud    = Color(0xFF3A3A5A);
  static const _dayHUDMain    = Color(0xFF555555);
  static const _nightHUDMain  = Color(0xFFCCCCEE);
  static const _dayHUDSub     = Color(0xFF999999);
  static const _nightHUDSub   = Color(0xFF8888AA);

  // ── Pre-allocated paints ───────────────────────────────────
  final Paint _skyPaint = Paint();
  final Paint _groundPaint = Paint()
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final Paint _groundTickPaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  final Paint _dinoPaint = Paint();
  final Paint _dinoLegPaint = Paint();
  final Paint _dinoEyePaint = Paint()..color = const Color(0xFFF7F7F7);
  final Paint _obstaclePaint = Paint();
  final Paint _obstacleDarkPaint = Paint()..strokeWidth = 2;
  final Paint _cloudPaint = Paint();
  final Paint _birdPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final Paint _flashPaint = Paint();

  static const double _tileWidth = 60;

  GamePainter({
    required this.dino,
    required this.obstacles,
    required this.birds,
    required this.clouds,
    required this.ground,
    required this.groundY,
    required this.gameState,
    required this.score,
    required this.highScore,
    required this.timeOfDay,
    required this.flashTimer,
  });

  // Lerp helper — call once per frame per color, store result in paint
  Color _lerp(Color day, Color night) =>
      Color.lerp(day, night, timeOfDay)!;

  @override
  void paint(Canvas canvas, Size size) {
    // Update paint colors based on current timeOfDay
    _skyPaint.color           = _lerp(_daySky, _nightSky);
    _groundPaint.color        = _lerp(_dayGround, _nightGround);
    _groundTickPaint.color    = _lerp(_dayGroundTick, _nightGroundTick);
    _dinoPaint.color          = _lerp(_dayDino, _nightDino);
    _dinoLegPaint.color       = _lerp(_dayDino, _nightDino);
    _obstaclePaint.color      = _lerp(_dayCactus, _nightCactus);
    _birdPaint.color          = _lerp(_dayBird, _nightBird);

    _drawSky(canvas, size);
    _drawStars(canvas, size);       // visible only at night
    _drawClouds(canvas);
    _drawGround(canvas, size);
    _drawObstacles(canvas);
    _drawBirds(canvas);
    _drawDino(canvas);
    _drawHUD(canvas, size);
    _drawCollisionFlash(canvas, size);

    if (gameState == GameState.initial) {
      _drawOverlay(canvas, size, 'TAP TO START', null);
    } else if (gameState == GameState.gameOver) {
      _drawOverlay(canvas, size, 'GAME OVER', 'TAP TO RESTART');
    }
  }

  // ── Sky + stars ────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _skyPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    if (timeOfDay < 0.3) return; // stars only visible after dusk
    final opacity = ((timeOfDay - 0.3) / 0.4).clamp(0.0, 1.0);
    final starPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity * 0.8);

    // Fixed star positions using deterministic offsets
    // (same positions every frame — no Random() in paint())
    final positions = [
      const Offset(60, 30),  const Offset(180, 55), const Offset(310, 20),
      const Offset(420, 45), const Offset(550, 25), const Offset(640, 60),
      const Offset(100, 80), const Offset(260, 70), const Offset(490, 75),
      const Offset(720, 40), const Offset(800, 65), const Offset(380, 88),
    ];

    for (final pos in positions) {
      if (pos.dx < size.width) {
        canvas.drawCircle(pos, 1.5, starPaint);
      }
    }
  }

  // ── Clouds ─────────────────────────────────────────────────

  void _drawCloud(Canvas canvas, Clouds cloud) {
    final base = _lerp(_dayCloud, _nightCloud);
    _cloudPaint.color = base.withOpacity(cloud.opacity * (timeOfDay > 0.5 ? 0.6 : 1.0));

    final cx = cloud.X + cloud.width / 2;
    final cy = cloud.Y;
    final r = cloud.width / 4;

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
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), _groundPaint);

    _groundTickPaint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, groundY + 4), Offset(size.width, groundY + 4), _groundTickPaint);

    final scrollX = ground.scrollOffset % _tileWidth;
    for (double x = -scrollX; x < size.width; x += _tileWidth) {
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

    // Body
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, w, h * 0.7),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(14),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      _dinoPaint,
    );

    // Head bump
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.55, y - h * 0.12, w * 0.45, h * 0.3),
        const Radius.circular(8),
      ),
      _dinoPaint,
    );

    // Eye
    canvas.drawCircle(Offset(x + w * 0.82, y - h * 0.02), 4, _dinoEyePaint);
    canvas.drawCircle(Offset(x + w * 0.85, y - h * 0.02), 2, _dinoLegPaint);

    _drawLegs(canvas, x, y, w, h);
  }

  void _drawLegs(Canvas canvas, double x, double y, double w, double h) {
    final legY = y + h * 0.68;
    final legH = h * 0.32;
    final legW = w * 0.18;
    final lx = x + w * 0.25;
    final rx = x + w * 0.55;

    if (dino.isOnGround) {
      final lo = dino.leftLegUp ? -legH * 0.35 : 0.0;
      final ro = dino.leftLegUp ? 0.0 : -legH * 0.35;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, legY + lo, legW, legH), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, legY + ro, legW, legH), const Radius.circular(3)), _dinoLegPaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx - 4, legY - legH * 0.1, legW, legH * 0.85), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx - 4, legY, legW, legH * 0.85), const Radius.circular(3)), _dinoLegPaint);
    }
  }

  // ── Obstacles ──────────────────────────────────────────────

  void _drawObstacles(Canvas canvas) {
    for (final obs in obstacles) {
      switch (obs.type) {
        case ObstacleType.smallCactus:
          _drawSmallCactus(canvas, obs);
        case ObstacleType.tallCactus:
          _drawTallCactus(canvas, obs);
        case ObstacleType.wideCactus:
          _drawWideCactus(canvas, obs);
      }
    }
  }

  void _drawSmallCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y;
    final w = obs.width; final h = obs.height;

    // Trunk
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.3, y, w * 0.4, h), const Radius.circular(3)), _obstaclePaint);
    // Left arm
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + h * 0.15, w * 0.32, h * 0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + h * 0.3, w * 0.35, h * 0.15), const Radius.circular(3)), _obstaclePaint);
    // Right arm
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.68, y + h * 0.2, w * 0.32, h * 0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.65, y + h * 0.35, w * 0.35, h * 0.15), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawTallCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y;
    final w = obs.width; final h = obs.height;

    // Tall trunk
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.32, y, w * 0.36, h), const Radius.circular(4)), _obstaclePaint);
    // One high arm on the left
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + h * 0.1, w * 0.34, h * 0.22), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + h * 0.1, w * 0.25, h * 0.38), const Radius.circular(3)), _obstaclePaint);
    // Low arm on right
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.66, y + h * 0.4, w * 0.34, h * 0.18), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.7, y + h * 0.28, w * 0.25, h * 0.28), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawWideCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y;
    final w = obs.width; final h = obs.height;

    // Two trunks side by side
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.05, y + h * 0.15, w * 0.3, h * 0.85), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.62, y, w * 0.3, h), const Radius.circular(3)), _obstaclePaint);
    // Bridge connecting them
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.05, y + h * 0.35, w * 0.9, h * 0.18), const Radius.circular(3)), _obstaclePaint);
    // Small top nubs
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.1, y + h * 0.08, w * 0.2, h * 0.2), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.65, y - h * 0.05, w * 0.2, h * 0.2), const Radius.circular(3)), _obstaclePaint);
  }

  // ── Birds ──────────────────────────────────────────────────

  void _drawBirds(Canvas canvas) {
    for (final bird in birds) {
      _drawBird(canvas, bird);
    }
  }

  void _drawBird(Canvas canvas, Bird bird) {
    // Wing flap: sine wave drives how high each wing is
    // sin() oscillates between -1 and 1 naturally — perfect for animation
    final flapAngle = sin(bird.flapTime * 8.0); // 8.0 = flap speed
    final wingDip = flapAngle * 8.0;             // max 8px dip

    final cx = bird.x + bird.width / 2;
    final cy = bird.y + bird.height / 2;

    // Left wing — curves upward on positive flapAngle
    final leftPath = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
        cx - bird.width * 0.3, cy - 10 + wingDip,
        cx - bird.width * 0.5, cy + wingDip,
      );

    // Right wing — mirrors the left
    final rightPath = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
        cx + bird.width * 0.3, cy - 10 + wingDip,
        cx + bird.width * 0.5, cy + wingDip,
      );

    canvas.drawPath(leftPath, _birdPaint);
    canvas.drawPath(rightPath, _birdPaint);

    // Body dot
    canvas.drawCircle(Offset(cx, cy), 3, _birdPaint..style = PaintingStyle.fill);
    _birdPaint.style = PaintingStyle.stroke; // restore stroke for next bird
  }

  // ── Collision flash ────────────────────────────────────────

  void _drawCollisionFlash(Canvas canvas, Size size) {
    if (flashTimer <= 0) return;
    // Opacity fades out as flashTimer counts down
    final opacity = (flashTimer / 0.25).clamp(0.0, 1.0) * 0.6;
    _flashPaint.color = Color.fromRGBO(255, 80, 80, opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _flashPaint);
  }

  // ── HUD ────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    final mainColor = _lerp(_dayHUDMain, _nightHUDMain);
    final subColor  = _lerp(_dayHUDSub,  _nightHUDSub);

    _drawText(canvas, 'Score: ${score.toString().padLeft(5, '0')}',
      Offset(size.width - 160, 20), fontSize: 18, color: mainColor,
      fontWeight: FontWeight.bold);

    if (highScore > 0) {
      _drawText(canvas, 'HI: ${highScore.toString().padLeft(5, '0')}',
        Offset(size.width - 310, 20), fontSize: 18, color: subColor,
        fontWeight: FontWeight.bold);
    }
  }

  // ── Overlays ───────────────────────────────────────────────

  void _drawOverlay(Canvas canvas, Size size, String title, String? subtitle) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0x55000000),
    );

    final cy = size.height / 2;

    _drawText(canvas, title, Offset(0, cy - 44), fontSize: 38,
      color: Colors.white, fontWeight: FontWeight.bold,
      textAlign: TextAlign.center, width: size.width);

    if (subtitle != null) {
      _drawText(canvas, subtitle, Offset(0, cy + 16), fontSize: 20,
        color: Colors.white70, textAlign: TextAlign.center, width: size.width);
    }

    if (gameState == GameState.gameOver && highScore > 0) {
      _drawText(canvas, 'Best: $highScore', Offset(0, cy + 54),
        fontSize: 17, color: Colors.white54,
        textAlign: TextAlign.center, width: size.width);
    }
  }

  // ── Text helper ────────────────────────────────────────────

  void _drawText(Canvas canvas, String text, Offset position, {
    double fontSize = 16,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
    double? width,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        color: color, fontSize: fontSize, fontWeight: fontWeight,
        fontFamily: 'monospace', letterSpacing: 1.2,
      )),
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
  bool shouldRepaint(GamePainter old) => true;
}