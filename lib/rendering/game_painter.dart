/// Renders the entire game scene using Flutter's Canvas API. 
/// CustomPainter.paint() is called every frame (when shouldRepaint
/// returns true). We receive a Canvas — our drawing surface — and
/// a Size — the available space.
/// 
/// Canvas coordinate system:
///   (0,0) is TOP-LEFT
///   X increases rightward
///   Y increases DOWNWARD
///   All units are logical pixels


import 'package:dino_game/models/clouds.dart';
import 'package:dino_game/utils/daynightcolors.dart';
import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../core/game_state.dart';
import '../models/ground.dart';
import '../models/birds.dart';
import 'dart:math';

/*class GamePainter extends CustomPainter {
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
  final double shakeMagnitude;
  final bool isCelebrating;
  final double celebrationOpacity;
  final int celebrationScore;
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

    final Paint _particlePaint    = Paint();

  final Random _shakeRandom = Random(42); // seeded for deterministic shake

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
      required this.shakeMagnitude,
    required this.isCelebrating,
    required this.celebrationOpacity,
    required this.celebrationScore,
  });

  // Lerp helper — call once per frame per color, store result in paint
  Color _lerp(Color day, Color night) =>
      Color.lerp(day, night, timeOfDay)!;

  @override
  void paint(Canvas canvas, Size size) {
    // Update paint colors based on current timeOfDay
    _skyPaint.color           = _lerp(DayNightColors.daySky, DayNightColors.nightSky);
    _groundPaint.color        = _lerp(DayNightColors.dayGround, DayNightColors.nightGround);
    _groundTickPaint.color    = _lerp(DayNightColors.dayGroundTick, DayNightColors.nightGroundTick);
    _dinoPaint.color          = _lerp(DayNightColors.dayDino, DayNightColors.nightDino);
    _dinoLegPaint.color       = _lerp(DayNightColors.dayDino, DayNightColors.nightDino);
    _obstaclePaint.color      = _lerp(DayNightColors.dayCactus, DayNightColors.nightCactus);
    _birdPaint.color          = _lerp(DayNightColors.dayBird, DayNightColors.nightBird);

     // Apply screen shake by translating the canvas
    // Everything drawn after this translate shifts by the shake offset
    if (shakeMagnitude > 0) {
      final shakeX = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 12;
      final shakeY = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 8;
      canvas.save();
      canvas.translate(shakeX, shakeY);
    }

    _drawSky(canvas, size);
    _drawStars(canvas, size);       // visible only at night
    _drawClouds(canvas);
    _drawGround(canvas, size);
    _drawObstacles(canvas);
    _drawBirds(canvas);
    _drawDino(canvas);
    // Restore canvas before drawing HUD (HUD shouldn't shake)
    if (shakeMagnitude > 0) canvas.restore();
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
    final base = _lerp(DayNightColors.dayCloud, DayNightColors.nightCloud);
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
    final mainColor = _lerp(DayNightColors.dayHUDMain, DayNightColors.nightHUDMain);
    final subColor  = _lerp(DayNightColors.dayHUDSub,  DayNightColors.nightHUDSub);

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
}*/


/*import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../models/ground.dart';
import '../models/particle.dart';
import '../core/game_state.dart';

class GamePainter extends CustomPainter {
  final Dino dino;
  final List<Obstacle> obstacles;
  final List<Bird> birds;
  final List<Clouds> clouds;
  final Ground ground;
  final List<Particle> particles;
  final double groundY;
  final GameState gameState;
  final int score;
  final int highScore;
  final double timeOfDay;
  final double flashTimer;
  final double shakeMagnitude;
  final bool isCelebrating;
  final double celebrationOpacity;
  final int celebrationScore;

  // ── Day/night palettes ─────────────────────────────────────
  static const _daySky          = Color(0xFFF7F7F7);
  static const _nightSky        = Color(0xFF1A1A2E);
  static const _dayGround       = Color(0xFF9E8B70);
  static const _nightGround     = Color(0xFF4A4060);
  static const _dayGroundTick   = Color(0xFFB8A898);
  static const _nightGroundTick = Color(0xFF6A5A80);
  static const _dayDino         = Color(0xFF555555);
  static const _nightDino       = Color(0xFF8888BB);
  static const _dayCactus       = Color(0xFF3A8A3A);
  static const _nightCactus     = Color(0xFF2A6A5A);
  static const _dayBird         = Color(0xFF666666);
  static const _nightBird       = Color(0xFF9999CC);
  static const _dayHUDMain      = Color(0xFF555555);
  static const _nightHUDMain    = Color(0xFFCCCCEE);
  static const _dayHUDSub       = Color(0xFF999999);
  static const _nightHUDSub     = Color(0xFF8888AA);

  // ── Pre-allocated paints ───────────────────────────────────
  final Paint _skyPaint         = Paint();
  final Paint _groundPaint      = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round;
  final Paint _groundTickPaint  = Paint()..strokeWidth = 1.5..strokeCap = StrokeCap.round;
  final Paint _dinoPaint        = Paint();
  final Paint _dinoLegPaint     = Paint();
  final Paint _dinoEyePaint     = Paint()..color = const Color(0xFFF7F7F7);
  final Paint _obstaclePaint    = Paint();
  final Paint _cloudPaint       = Paint();
  final Paint _birdPaint        = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final Paint _particlePaint    = Paint();
  final Paint _flashPaint       = Paint();

  static const double _tileWidth = 60;
  final Random _shakeRandom = Random(42); // seeded for deterministic shake

  GamePainter({
    required this.dino,
    required this.obstacles,
    required this.birds,
    required this.clouds,
    required this.ground,
    required this.particles,
    required this.groundY,
    required this.gameState,
    required this.score,
    required this.highScore,
    required this.timeOfDay,
    required this.flashTimer,
    required this.shakeMagnitude,
    required this.isCelebrating,
    required this.celebrationOpacity,
    required this.celebrationScore,
  });

  Color _lerp(Color day, Color night) => Color.lerp(day, night, timeOfDay)!;

  @override
  void paint(Canvas canvas, Size size) {
    // Update lerped paint colors
    _skyPaint.color        = _lerp(_daySky, _nightSky);
    _groundPaint.color     = _lerp(_dayGround, _nightGround);
    _groundTickPaint.color = _lerp(_dayGroundTick, _nightGroundTick);
    _dinoPaint.color       = _lerp(_dayDino, _nightDino);
    _dinoLegPaint.color    = _lerp(_dayDino, _nightDino);
    _obstaclePaint.color   = _lerp(_dayCactus, _nightCactus);
    _birdPaint.color       = _lerp(_dayBird, _nightBird);

    // Apply screen shake by translating the canvas
    // Everything drawn after this translate shifts by the shake offset
    if (shakeMagnitude > 0) {
      final shakeX = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 12;
      final shakeY = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 8;
      canvas.save();
      canvas.translate(shakeX, shakeY);
    }

    _drawSky(canvas, size);
    _drawStars(canvas, size);
    _drawClouds(canvas);
    _drawGround(canvas, size);
    _drawObstacles(canvas);
    _drawBirds(canvas);
    _drawDino(canvas);
    _drawParticles(canvas);

    // Restore canvas before drawing HUD (HUD shouldn't shake)
    if (shakeMagnitude > 0) canvas.restore();

    _drawHUD(canvas, size);
    _drawMilestoneCelebration(canvas, size);
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
    if (timeOfDay < 0.3) return;
    final opacity = ((timeOfDay - 0.3) / 0.4).clamp(0.0, 1.0);
    final starPaint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity * 0.8);
    const positions = [
      Offset(60, 30),  Offset(180, 55), Offset(310, 20),
      Offset(420, 45), Offset(550, 25), Offset(640, 60),
      Offset(100, 80), Offset(260, 70), Offset(490, 75),
      Offset(380, 88), Offset(150, 40), Offset(500, 50),
    ];
    for (final pos in positions) {
      if (pos.dx < size.width) canvas.drawCircle(pos, 1.5, starPaint);
    }
  }

  // ── Clouds ─────────────────────────────────────────────────

  void _drawClouds(Canvas canvas) {
    for (final cloud in clouds) {
      final base = _lerp(const Color(0xFFDDDDDD), const Color(0xFF3A3A5A));
      _cloudPaint.color = base.withOpacity(cloud.opacity);
      final cx = cloud.X + cloud.width / 2;
      final cy = cloud.Y;
      final r  = cloud.width / 4;
      canvas.drawCircle(Offset(cx, cy), r, _cloudPaint);
      canvas.drawCircle(Offset(cx - r * 0.8, cy + r * 0.3), r * 0.7, _cloudPaint);
      canvas.drawCircle(Offset(cx + r * 0.8, cy + r * 0.3), r * 0.7, _cloudPaint);
      canvas.drawCircle(Offset(cx - r * 1.4, cy + r * 0.6), r * 0.55, _cloudPaint);
      canvas.drawCircle(Offset(cx + r * 1.4, cy + r * 0.6), r * 0.55, _cloudPaint);
    }
  }

  // ── Ground ─────────────────────────────────────────────────

  void _drawGround(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), _groundPaint);
    _groundTickPaint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, groundY + 4), Offset(size.width, groundY + 4), _groundTickPaint);
    final scrollX = ground.scrollOffset % _tileWidth;
    for (double x = -scrollX; x < size.width; x += _tileWidth) {
      canvas.drawLine(Offset(x, groundY + 2), Offset(x + 12, groundY + 2), _groundTickPaint);
    }
  }

  // ── Dino ───────────────────────────────────────────────────

  void _drawDino(Canvas canvas) {
    if (dino.isDucking) {
      _drawDinoDucked(canvas);
    } else {
      _drawDinoUpright(canvas);
    }
  }

  void _drawDinoUpright(Canvas canvas) {
    final x = dino.x; final y = dino.y;
    final w = dino.width; final h = dino.height;

    // Body
    canvas.drawRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, w, h * 0.7),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    ), _dinoPaint);

    // Head bump
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.55, y - h * 0.12, w * 0.45, h * 0.3),
      const Radius.circular(8),
    ), _dinoPaint);

    // Eye
    canvas.drawCircle(Offset(x + w * 0.82, y - h * 0.02), 4, _dinoEyePaint);
    canvas.drawCircle(Offset(x + w * 0.85, y - h * 0.02), 2, _dinoLegPaint);

    _drawLegsUpright(canvas, x, y, w, h);
  }

  void _drawDinoDucked(Canvas canvas) {
    // When ducked: wide and flat, head stretched forward
    final x = dino.x;
    // Visual y position for duck — anchored to ground
    final y = dino.y + dino.height * 0.5;
    final w = dino.width * 1.3;  // wider when ducked
    final h = dino.height * 0.45;

    // Low flat body
    canvas.drawRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, w, h),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(12),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    ), _dinoPaint);

    // Head pushed forward (right side)
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.6, y - h * 0.3, w * 0.42, h * 0.7),
      const Radius.circular(8),
    ), _dinoPaint);

    // Eye — lower position
    canvas.drawCircle(Offset(x + w * 0.92, y - h * 0.05), 3.5, _dinoEyePaint);
    canvas.drawCircle(Offset(x + w * 0.95, y - h * 0.05), 2, _dinoLegPaint);

    // Two flat legs scrambling
    _drawLegsDucked(canvas, x, y, w, h);
  }

  void _drawLegsUpright(Canvas canvas, double x, double y, double w, double h) {
    final legY = y + h * 0.68;
    final legH = h * 0.32;
    final legW = w * 0.18;
    final lx   = x + w * 0.25;
    final rx   = x + w * 0.55;

    if (dino.isOnGround) {
      final lo = dino.leftLegUp ? -legH * 0.35 : 0.0;
      final ro = dino.leftLegUp ? 0.0 : -legH * 0.35;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, legY + lo, legW, legH), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, legY + ro, legW, legH), const Radius.circular(3)), _dinoLegPaint);
    } else {
      // Tucked airborne legs
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx - 4, legY - legH * 0.1, legW, legH * 0.85), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx - 4, legY, legW, legH * 0.85), const Radius.circular(3)), _dinoLegPaint);
    }
  }

  void _drawLegsDucked(Canvas canvas, double x, double y, double w, double h) {
    // Short scrambling legs below flat body
    final legY = y + h * 0.8;
    final legH = h * 0.4;
    final legW = w * 0.13;

    final lo = dino.leftLegUp ? -legH * 0.4 : 0.0;
    final ro = dino.leftLegUp ? 0.0 : -legH * 0.4;

    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.2, legY + lo, legW, legH), const Radius.circular(3)), _dinoLegPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.42, legY + ro, legW, legH), const Radius.circular(3)), _dinoLegPaint);
  }

  // ── Obstacles ──────────────────────────────────────────────

  void _drawObstacles(Canvas canvas) {
    for (final obs in obstacles) {
      switch (obs.type) {
        case ObstacleType.smallCactus: _drawSmallCactus(canvas, obs);
        case ObstacleType.tallCactus:  _drawTallCactus(canvas, obs);
        case ObstacleType.wideCactus:  _drawWideCactus(canvas, obs);
      }
    }
  }

  void _drawSmallCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y; final w = obs.width; final h = obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w*0.3, y, w*0.4, h), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y+h*0.15, w*0.32, h*0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y+h*0.3, w*0.35, h*0.15), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.68, y+h*0.2, w*0.32, h*0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.65, y+h*0.35, w*0.35, h*0.15), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawTallCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y; final w = obs.width; final h = obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.32, y, w*0.36, h), const Radius.circular(4)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y+h*0.1, w*0.34, h*0.22), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y+h*0.1, w*0.25, h*0.38), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.66, y+h*0.4, w*0.34, h*0.18), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.7, y+h*0.28, w*0.25, h*0.28), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawWideCactus(Canvas canvas, Obstacle obs) {
    final x = obs.x; final y = obs.y; final w = obs.width; final h = obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.05, y+h*0.15, w*0.3, h*0.85), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.62, y, w*0.3, h), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.05, y+h*0.35, w*0.9, h*0.18), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.1, y+h*0.08, w*0.2, h*0.2), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.65, y-h*0.05, w*0.2, h*0.2), const Radius.circular(3)), _obstaclePaint);
  }

  // ── Birds ──────────────────────────────────────────────────

  void _drawBirds(Canvas canvas) {
    for (final bird in birds) {
      final flapAngle = sin(bird.flapTime * 8.0);
      final wingDip   = flapAngle * 8.0;
      final cx = bird.x + bird.width / 2;
      final cy = bird.y + bird.height / 2;

      final leftPath = Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(cx - bird.width*0.3, cy - 10 + wingDip, cx - bird.width*0.5, cy + wingDip);
      final rightPath = Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(cx + bird.width*0.3, cy - 10 + wingDip, cx + bird.width*0.5, cy + wingDip);

      canvas.drawPath(leftPath, _birdPaint);
      canvas.drawPath(rightPath, _birdPaint);
      _birdPaint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 3, _birdPaint);
      _birdPaint.style = PaintingStyle.stroke;
    }
  }

  // ── Particles ──────────────────────────────────────────────

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      // Fade out as lifetime decreases
      _particlePaint.color = p.color.withOpacity(p.lifetime.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.radius * p.lifetime, _particlePaint);
    }
  }

  // ── Collision flash ────────────────────────────────────────

  void _drawCollisionFlash(Canvas canvas, Size size) {
    if (flashTimer <= 0) return;
    final opacity = (flashTimer / _flashDuration).clamp(0.0, 1.0) * 0.55;
    _flashPaint.color = Color.fromRGBO(255, 80, 80, opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _flashPaint);
  }

  static const double _flashDuration = 0.25;

  // ── Milestone celebration ──────────────────────────────────

  void _drawMilestoneCelebration(Canvas canvas, Size size) {
    if (!isCelebrating || celebrationOpacity <= 0) return;

    _drawText(
      canvas,
      '$celebrationScore!',
      Offset(0, size.height * 0.35),
      fontSize: 52,
      color: const Color(0xFFFFAB40).withOpacity(celebrationOpacity),
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
      width: size.width,
    );
  }

  // ── HUD ────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    final mainColor = _lerp(_dayHUDMain, _nightHUDMain);
    final subColor  = _lerp(_dayHUDSub,  _nightHUDSub);

    _drawText(canvas, 'Score: ${score.toString().padLeft(5, '0')}',
      Offset(size.width - 160, 20), fontSize: 18,
      color: mainColor, fontWeight: FontWeight.bold);

    if (highScore > 0) {
      _drawText(canvas, 'HI: ${highScore.toString().padLeft(5, '0')}',
        Offset(size.width - 310, 20), fontSize: 18,
        color: subColor, fontWeight: FontWeight.bold);
    }

    // Duck hint shown at the start
    if (gameState == GameState.playing && score < 100) {
      _drawText(canvas, 'Hold to duck',
        Offset(0, size.height - 40), fontSize: 14,
        color: mainColor.withOpacity(0.5),
        textAlign: TextAlign.center, width: size.width);
    }
  }

  // ── Overlays ───────────────────────────────────────────────

  void _drawOverlay(Canvas canvas, Size size, String title, String? subtitle) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0x55000000));

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
}*/

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../models/obstacle.dart';
import '../models/ground.dart';
import '../models/particle.dart';
import '../core/game_state.dart';
import '../core/sprite_loader.dart';

class GamePainter extends CustomPainter {
  final Dino dino;
  final List<Obstacle> obstacles;
  final List<Bird> birds;
  final List<Clouds> clouds;
  final Ground ground;
  final List<Particle> particles;
  final GameSprites sprites;
  final double groundY;
  final GameState gameState;
  final int score;
  final int highScore;
  final double timeOfDay;
  final double flashTimer;
  final double shakeMagnitude;
  final bool isCelebrating;
  final double celebrationOpacity;
  final int celebrationScore;
  final double totalTime; // drives title bob

  // ── Palettes ───────────────────────────────────────────────
  static const _daySky          = Color(0xFFF7F7F7);
  static const _nightSky        = Color(0xFF1A1A2E);
  static const _dayGround       = Color(0xFF9E8B70);
  static const _nightGround     = Color(0xFF4A4060);
  static const _dayGroundTick   = Color(0xFFB8A898);
  static const _nightGroundTick = Color(0xFF6A5A80);
  static const _dayDino         = Color(0xFF555555);
  static const _nightDino       = Color(0xFF8888BB);
  static const _dayCactus       = Color(0xFF3A8A3A);
  static const _nightCactus     = Color(0xFF2A6A5A);
  static const _dayBird         = Color(0xFF666666);
  static const _nightBird       = Color(0xFF9999CC);
  static const _dayHUDMain      = Color(0xFF555555);
  static const _nightHUDMain    = Color(0xFFCCCCEE);
  static const _dayHUDSub       = Color(0xFF999999);
  static const _nightHUDSub     = Color(0xFF8888AA);

  // ── Paints ─────────────────────────────────────────────────
  final Paint _skyPaint        = Paint();
  final Paint _groundPaint     = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round;
  final Paint _groundTickPaint = Paint()..strokeWidth = 1.5..strokeCap = StrokeCap.round;
  final Paint _dinoPaint       = Paint();
  final Paint _dinoLegPaint    = Paint();
  final Paint _dinoEyePaint    = Paint()..color = const Color(0xFFF7F7F7);
  final Paint _obstaclePaint   = Paint();
  final Paint _cloudPaint      = Paint();
  final Paint _birdPaint       = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final Paint _particlePaint   = Paint();
  final Paint _flashPaint      = Paint();
  final Paint _spritePaint     = Paint();  // for drawImageRect

  static const double _tileWidth    = 60;
  static const double _flashDuration = 0.25;
  final Random _shakeRandom = Random(42);

  GamePainter({
    required this.dino,
    required this.obstacles,
    required this.birds,
    required this.clouds,
    required this.ground,
    required this.particles,
    required this.sprites,
    required this.groundY,
    required this.gameState,
    required this.score,
    required this.highScore,
    required this.timeOfDay,
    required this.flashTimer,
    required this.shakeMagnitude,
    required this.isCelebrating,
    required this.celebrationOpacity,
    required this.celebrationScore,
    required this.totalTime,
  });

  Color _lerp(Color day, Color night) => Color.lerp(day, night, timeOfDay)!;

  @override
  void paint(Canvas canvas, Size size) {
    _skyPaint.color        = _lerp(_daySky, _nightSky);
    _groundPaint.color     = _lerp(_dayGround, _nightGround);
    _groundTickPaint.color = _lerp(_dayGroundTick, _nightGroundTick);
    _dinoPaint.color       = _lerp(_dayDino, _nightDino);
    _dinoLegPaint.color    = _lerp(_dayDino, _nightDino);
    _obstaclePaint.color   = _lerp(_dayCactus, _nightCactus);
    _birdPaint.color       = _lerp(_dayBird, _nightBird);

    // Screen shake — save canvas state, translate, draw world, restore
    if (shakeMagnitude > 0) {
      final sx = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 12;
      final sy = (_shakeRandom.nextDouble() - 0.5) * shakeMagnitude * 8;
      canvas.save();
      canvas.translate(sx, sy);
    }

    _drawSky(canvas, size);
    _drawStars(canvas, size);
    _drawClouds(canvas);
    _drawGround(canvas, size);
    _drawObstacles(canvas);
    _drawBirds(canvas);
    _drawDino(canvas);
    _drawParticles(canvas);

    if (shakeMagnitude > 0) canvas.restore();

    // HUD and overlays drawn after restore — they don't shake
    _drawHUD(canvas, size);
    _drawMilestoneCelebration(canvas, size);
    _drawCollisionFlash(canvas, size);

    if (gameState == GameState.initial) _drawStartScreen(canvas, size);
    else if (gameState == GameState.gameOver) _drawGameOverScreen(canvas, size);
  }

  // ── Sprite helper ──────────────────────────────────────────

  /// Draws a sprite image scaled to fit [dest].
  /// Falls back to drawing [fallback] if image is null.
  void _drawSprite(Canvas canvas, ui.Image? image, Rect dest,
      void Function() fallback) {
    if (image != null) {
      final src = Rect.fromLTWH(
          0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, src, dest, _spritePaint);
    } else {
      fallback();
    }
  }

  // ── Sky ────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) =>
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _skyPaint);

  void _drawStars(Canvas canvas, Size size) {
    if (timeOfDay < 0.3) return;
    final opacity = ((timeOfDay - 0.3) / 0.4).clamp(0.0, 1.0);
    final p = Paint()..color = Color.fromRGBO(255, 255, 255, opacity * 0.8);
    const stars = [
      Offset(60,30), Offset(180,55), Offset(310,20), Offset(420,45),
      Offset(550,25), Offset(640,60), Offset(100,80), Offset(260,70),
      Offset(490,75), Offset(380,88), Offset(150,40), Offset(500,50),
    ];
    for (final s in stars) {
      if (s.dx < size.width) canvas.drawCircle(s, 1.5, p);
    }
  }

  // ── Clouds ─────────────────────────────────────────────────

  void _drawClouds(Canvas canvas) {
    for (final cloud in clouds) {
      final base = _lerp(const Color(0xFFDDDDDD), const Color(0xFF3A3A5A));
      _cloudPaint.color = base.withOpacity(cloud.opacity);
      final cx = cloud.X + cloud.width / 2;
      final cy = cloud.Y;
      final r  = cloud.width / 4;
      canvas.drawCircle(Offset(cx, cy), r, _cloudPaint);
      canvas.drawCircle(Offset(cx - r*0.8, cy + r*0.3), r*0.7, _cloudPaint);
      canvas.drawCircle(Offset(cx + r*0.8, cy + r*0.3), r*0.7, _cloudPaint);
      canvas.drawCircle(Offset(cx - r*1.4, cy + r*0.6), r*0.55, _cloudPaint);
      canvas.drawCircle(Offset(cx + r*1.4, cy + r*0.6), r*0.55, _cloudPaint);
    }
  }

  // ── Ground ─────────────────────────────────────────────────

  void _drawGround(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), _groundPaint);
    _groundTickPaint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, groundY+4), Offset(size.width, groundY+4), _groundTickPaint);
    final scrollX = ground.scrollOffset % _tileWidth;
    for (double x = -scrollX; x < size.width; x += _tileWidth) {
      canvas.drawLine(Offset(x, groundY+2), Offset(x+12, groundY+2), _groundTickPaint);
    }
  }

  // ── Dino ───────────────────────────────────────────────────

  void _drawDino(Canvas canvas) {
    if (dino.isDucking) {
      _drawSprite(canvas, sprites.dinoDuck, dino.duckBounds,
          () => _drawDinoDuckedShape(canvas));
    } else if (!dino.isOnGround) {
      _drawSprite(canvas, sprites.dinoJump, dino.bounds,
          () => _drawDinoUprightShape(canvas));
    } else {
      // Alternate run frames
      final runSprite = dino.leftLegUp ? sprites.dinoRun1 : sprites.dinoRun2;
      _drawSprite(canvas, runSprite, dino.bounds,
          () => _drawDinoUprightShape(canvas));
    }
  }

  void _drawDinoUprightShape(Canvas canvas) {
    final x = dino.x; final y = dino.y;
    final w = dino.width; final h = dino.height;

    canvas.drawRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, w, h*0.7),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    ), _dinoPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+w*0.55, y-h*0.12, w*0.45, h*0.3),
      const Radius.circular(8),
    ), _dinoPaint);

    canvas.drawCircle(Offset(x+w*0.82, y-h*0.02), 4, _dinoEyePaint);
    canvas.drawCircle(Offset(x+w*0.85, y-h*0.02), 2, _dinoLegPaint);
    _drawLegsUprightShape(canvas, x, y, w, h);
  }

  void _drawLegsUprightShape(Canvas canvas, double x, double y, double w, double h) {
    final legY = y + h*0.68; final legH = h*0.32;
    final legW = w*0.18;
    final lx = x+w*0.25; final rx = x+w*0.55;

    if (dino.isOnGround) {
      final lo = dino.leftLegUp ? -legH*0.35 : 0.0;
      final ro = dino.leftLegUp ?  0.0 : -legH*0.35;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, legY+lo, legW, legH), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, legY+ro, legW, legH), const Radius.circular(3)), _dinoLegPaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(lx-4, legY-legH*0.1, legW, legH*0.85), const Radius.circular(3)), _dinoLegPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rx-4, legY, legW, legH*0.85), const Radius.circular(3)), _dinoLegPaint);
    }
  }

  void _drawDinoDuckedShape(Canvas canvas) {
    final x = dino.x;
    final y = dino.y + dino.height * 0.5;
    final w = dino.width * 1.3;
    final h = dino.height * 0.45;

    canvas.drawRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, w, h),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(12),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    ), _dinoPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+w*0.6, y-h*0.3, w*0.42, h*0.7),
      const Radius.circular(8),
    ), _dinoPaint);

    canvas.drawCircle(Offset(x+w*0.92, y-h*0.05), 3.5, _dinoEyePaint);
    canvas.drawCircle(Offset(x+w*0.95, y-h*0.05), 2, _dinoLegPaint);

    final legY = y + h*0.8; final legH = h*0.4; final legW = w*0.13;
    final lo = dino.leftLegUp ? -legH*0.4 : 0.0;
    final ro = dino.leftLegUp ?  0.0 : -legH*0.4;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+w*0.2, legY+lo, legW, legH), const Radius.circular(3)), _dinoLegPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+w*0.42, legY+ro, legW, legH), const Radius.circular(3)), _dinoLegPaint);
  }

  // ── Obstacles ──────────────────────────────────────────────

  void _drawObstacles(Canvas canvas) {
    for (final obs in obstacles) {
      switch (obs.type) {
        case ObstacleType.smallCactus:
          _drawSprite(canvas, sprites.cactusSmall, obs.bounds,
              () => _drawSmallCactus(canvas, obs));
        case ObstacleType.tallCactus:
          _drawSprite(canvas, sprites.cactusTall, obs.bounds,
              () => _drawTallCactus(canvas, obs));
        case ObstacleType.wideCactus:
          _drawSprite(canvas, sprites.cactusWide, obs.bounds,
              () => _drawWideCactus(canvas, obs));
      }
    }
  }

  void _drawSmallCactus(Canvas canvas, Obstacle obs) {
    final x=obs.x; final y=obs.y; final w=obs.width; final h=obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.3,y,w*0.4,h), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y+h*0.15,w*0.32,h*0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y+h*0.3,w*0.35,h*0.15), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.68,y+h*0.2,w*0.32,h*0.3), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.65,y+h*0.35,w*0.35,h*0.15), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawTallCactus(Canvas canvas, Obstacle obs) {
    final x=obs.x; final y=obs.y; final w=obs.width; final h=obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.32,y,w*0.36,h), const Radius.circular(4)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y+h*0.1,w*0.34,h*0.22), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y+h*0.1,w*0.25,h*0.38), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.66,y+h*0.4,w*0.34,h*0.18), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.7,y+h*0.28,w*0.25,h*0.28), const Radius.circular(3)), _obstaclePaint);
  }

  void _drawWideCactus(Canvas canvas, Obstacle obs) {
    final x=obs.x; final y=obs.y; final w=obs.width; final h=obs.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.05,y+h*0.15,w*0.3,h*0.85), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.62,y,w*0.3,h), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.05,y+h*0.35,w*0.9,h*0.18), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.1,y+h*0.08,w*0.2,h*0.2), const Radius.circular(3)), _obstaclePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.65,y-h*0.05,w*0.2,h*0.2), const Radius.circular(3)), _obstaclePaint);
  }

  // ── Birds ──────────────────────────────────────────────────

  void _drawBirds(Canvas canvas) {
    for (final bird in birds) {
      // Alternate bird sprites on flap cycle
      final useFrame2 = sin(bird.flapTime * 8.0) > 0;
      final birdSprite = useFrame2 ? sprites.bird2 : sprites.bird1;
      _drawSprite(canvas, birdSprite, bird.bounds,
          () => _drawBirdShape(canvas, bird));
    }
  }

  void _drawBirdShape(Canvas canvas, Bird bird) {
    final flapAngle = sin(bird.flapTime * 8.0);
    final wingDip   = flapAngle * 8.0;
    final cx = bird.x + bird.width / 2;
    final cy = bird.y + bird.height / 2;

    final leftPath = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx-bird.width*0.3, cy-10+wingDip, cx-bird.width*0.5, cy+wingDip);
    final rightPath = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx+bird.width*0.3, cy-10+wingDip, cx+bird.width*0.5, cy+wingDip);

    canvas.drawPath(leftPath, _birdPaint);
    canvas.drawPath(rightPath, _birdPaint);
    _birdPaint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 3, _birdPaint);
    _birdPaint.style = PaintingStyle.stroke;
  }

  // ── Particles ──────────────────────────────────────────────

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      _particlePaint.color = p.color.withOpacity(p.lifetime.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.radius * p.lifetime, _particlePaint);
    }
  }

  // ── Flash ──────────────────────────────────────────────────

  void _drawCollisionFlash(Canvas canvas, Size size) {
    if (flashTimer <= 0) return;
    final opacity = (flashTimer / _flashDuration).clamp(0.0, 1.0) * 0.55;
    _flashPaint.color = Color.fromRGBO(255, 80, 80, opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _flashPaint);
  }

  // ── Milestone ──────────────────────────────────────────────

  void _drawMilestoneCelebration(Canvas canvas, Size size) {
    if (!isCelebrating || celebrationOpacity <= 0) return;
    _drawText(canvas, '$celebrationScore!',
      Offset(0, size.height * 0.35), fontSize: 52,
      color: const Color(0xFFFFAB40).withOpacity(celebrationOpacity),
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center, width: size.width);
  }

  // ── HUD ────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    final mainColor = _lerp(_dayHUDMain, _nightHUDMain);
    final subColor  = _lerp(_dayHUDSub,  _nightHUDSub);

    _drawText(canvas, 'Score: ${score.toString().padLeft(5, '0')}',
      Offset(size.width - 160, 20), fontSize: 18,
      color: mainColor, fontWeight: FontWeight.bold);

    if (highScore > 0) {
      _drawText(canvas, 'HI: ${highScore.toString().padLeft(5, '0')}',
        Offset(size.width - 310, 20), fontSize: 18,
        color: subColor, fontWeight: FontWeight.bold);
    }

    if (gameState == GameState.playing && score < 100) {
      _drawText(canvas, 'Hold to duck  ·  Tap to jump',
        Offset(0, size.height - 40), fontSize: 13,
        color: mainColor.withOpacity(0.45),
        textAlign: TextAlign.center, width: size.width);
    }
  }

  // ── Start screen ───────────────────────────────────────────

  void _drawStartScreen(Canvas canvas, Size size) {
    // Dim the background slightly
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0x33000000));

    // Title bobs gently using a sine wave on totalTime
    final titleBob = sin(totalTime * 2.0) * 6.0;
    final titleY   = size.height * 0.28 + titleBob;

    // Shadow
    _drawText(canvas, 'DINO RUN',
      Offset(2, titleY + 2), fontSize: 54,
      color: Colors.black26, fontWeight: FontWeight.bold,
      textAlign: TextAlign.center, width: size.width);

    // Title
    _drawText(canvas, 'DINO RUN',
      Offset(0, titleY), fontSize: 54,
      color: _lerp(const Color(0xFF444444), const Color(0xFFCCCCFF)),
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center, width: size.width);

    // Pulsing tap prompt — fades in and out using sine
    final promptOpacity = (sin(totalTime * 3.0) * 0.4 + 0.6).clamp(0.2, 1.0);
    _drawText(canvas, 'TAP TO START',
      Offset(0, size.height * 0.55), fontSize: 22,
      color: _lerp(const Color(0xFF666666), const Color(0xFFAAAADD))
          .withOpacity(promptOpacity),
      textAlign: TextAlign.center, width: size.width);

    // Controls hint
    _drawText(canvas, 'TAP = jump   HOLD = duck',
      Offset(0, size.height * 0.65), fontSize: 14,
      color: _lerp(const Color(0xFF999999), const Color(0xFF7777AA))
          .withOpacity(0.7),
      textAlign: TextAlign.center, width: size.width);

    // High score on start screen
    if (highScore > 0) {
      _drawText(canvas, 'Best: ${highScore.toString().padLeft(5, '0')}',
        Offset(0, size.height * 0.75), fontSize: 16,
        color: _lerp(const Color(0xFF888888), const Color(0xFF9999BB))
            .withOpacity(0.8),
        textAlign: TextAlign.center, width: size.width);
    }
  }

  // ── Game over screen ───────────────────────────────────────

  void _drawGameOverScreen(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0x66000000));

    final cy = size.height / 2;

    // GAME OVER text
    _drawText(canvas, 'GAME OVER',
      Offset(0, cy - 70), fontSize: 44,
      color: Colors.white, fontWeight: FontWeight.bold,
      textAlign: TextAlign.center, width: size.width);

    // Score achieved this round
    _drawText(canvas, 'Score  ${score.toString().padLeft(5, '0')}',
      Offset(0, cy - 10), fontSize: 22,
      color: Colors.white70,
      textAlign: TextAlign.center, width: size.width);

    // New high score callout
    if (score >= highScore && highScore > 0) {
      _drawText(canvas, '★  NEW BEST  ★',
        Offset(0, cy + 28), fontSize: 18,
        color: const Color(0xFFFFD54F),
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center, width: size.width);
    } else if (highScore > 0) {
      _drawText(canvas, 'Best  ${highScore.toString().padLeft(5, '0')}',
        Offset(0, cy + 28), fontSize: 18,
        color: Colors.white54,
        textAlign: TextAlign.center, width: size.width);
    }

    // Pulsing restart prompt
    final promptOpacity = (sin(totalTime * 3.0) * 0.4 + 0.6).clamp(0.2, 1.0);
    _drawText(canvas, 'TAP TO RESTART',
      Offset(0, cy + 74), fontSize: 20,
      color: Colors.white.withOpacity(promptOpacity),
      textAlign: TextAlign.center, width: size.width);
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
        color: color, fontSize: fontSize,
        fontWeight: fontWeight,
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