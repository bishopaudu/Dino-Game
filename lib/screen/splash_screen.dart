import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── animation controllers ────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _runController;
  late AnimationController _glowController;
  late AnimationController _textSlideController;
  late AnimationController _exitController;

  // ─── animations ──────────────────────────────────────────────────────────
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _glowPulse;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _exitFade;

  // dino running leg toggle
  bool _legToggle = false;

  // ground dots for parallax
  final List<_GroundDot> _groundDots = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initGroundDots();
    _initAnimations();
    _startSequence();
  }

  void _initGroundDots() {
    for (int i = 0; i < 20; i++) {
      _groundDots.add(_GroundDot(
        x: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.003 + 0.001,
      ));
    }
  }

  void _initAnimations() {
    // Fade in the whole splash
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Logo scale-in pop
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Dino running leg animation (looping)
    _runController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _runController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _runController.forward();
          setState(() => _legToggle = !_legToggle);
        }
      });

    // Glow pulse (looping)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 6.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text slide-up
    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _textSlideController, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
        parent: _textSlideController, curve: Curves.easeIn);

    // Exit fade-out
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );
  }

  Future<void> _startSequence() async {
    // 1. Fade in background
    await _fadeController.forward();

    // 2. Logo pops in
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Start running + glow
    _runController.forward();

    // 4. Slide text in
    await Future.delayed(const Duration(milliseconds: 200));
    _textSlideController.forward();

    // 5. Hold for a beat
    await Future.delayed(const Duration(milliseconds: 1800));

    // 6. Fade out and navigate
    await _exitController.forward();
    if (mounted) _navigateToGame();
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => GameProvider(),
          child: const GameScreen(),
        ),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _runController.dispose();
    _glowController.dispose();
    _textSlideController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: FadeTransition(
        opacity: _exitFade,
        child: FadeTransition(
          opacity: _fadeIn,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D1B2A),
            body: Stack(
              children: [
                // ── Scanline grid overlay ──────────────────────────────────
                _ScanlineOverlay(),

                // ── Animated ground dots (parallax) ───────────────────────
                AnimatedBuilder(
                  animation: _runController,
                  builder: (_, __) {
                    // move dots leftward
                    for (final dot in _groundDots) {
                      dot.x -= dot.speed;
                      if (dot.x < 0) dot.x = 1.0;
                    }
                    return CustomPaint(
                      size: size,
                      painter: _GroundDotPainter(_groundDots),
                    );
                  },
                ),

                // ── Main content ───────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ── Dino logo with glow ──────────────────────────────
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_logoScale, _glowPulse]),
                        builder: (_, __) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF76FF03)
                                        .withOpacity(0.35),
                                    blurRadius: _glowPulse.value * 2,
                                    spreadRadius: _glowPulse.value * 0.3,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // ── App title + subtitle ─────────────────────────────
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              // Title
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF76FF03),
                                    Color(0xFF00E5FF),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'DINO RUN',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 8,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'SURVIVE THE ENDLESS RUN',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF76FF03)
                                      .withOpacity(0.75),
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── Loading indicator ────────────────────────────────
                      FadeTransition(
                        opacity: _textFade,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: _PixelLoadingBar(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanline overlay painter
// ─────────────────────────────────────────────────────────────────────────────
class _ScanlineOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _ScanlinePainter()),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.55),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ground dot parallax
// ─────────────────────────────────────────────────────────────────────────────
class _GroundDot {
  double x;
  final double size;
  final double speed;

  _GroundDot({required this.x, required this.size, required this.speed});
}

class _GroundDotPainter extends CustomPainter {
  final List<_GroundDot> dots;
  _GroundDotPainter(this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.72;
    final paint = Paint()..color = const Color(0xFF76FF03).withOpacity(0.3);

    for (final dot in dots) {
      canvas.drawCircle(
        Offset(dot.x * size.width, groundY + (dot.x * 12 - 6)),
        dot.size,
        paint,
      );
    }

    // Ground line
    final linePaint = Paint()
      ..color = const Color(0xFF76FF03).withOpacity(0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, groundY + 8),
      Offset(size.width, groundY + 8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GroundDotPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pixel-style loading bar
// ─────────────────────────────────────────────────────────────────────────────
class _PixelLoadingBar extends StatefulWidget {
  @override
  State<_PixelLoadingBar> createState() => _PixelLoadingBarState();
}

class _PixelLoadingBarState extends State<_PixelLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..forward();
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _progress,
          builder: (_, __) {
            return CustomPaint(
              size: const Size(180, 12),
              painter: _PixelBarPainter(_progress.value),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'LOADING...',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 3,
            color: const Color(0xFF76FF03).withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _PixelBarPainter extends CustomPainter {
  final double progress;
  _PixelBarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const blockW = 10.0;
    const gap = 3.0;
    final totalBlocks = (size.width / (blockW + gap)).floor();
    final filledBlocks = (totalBlocks * progress).floor();

    // Background blocks
    final bgPaint = Paint()
      ..color = const Color(0xFF76FF03).withOpacity(0.1);
    // Filled blocks
    final fillPaint = Paint()..color = const Color(0xFF76FF03);
    // Glow on filled
    final glowPaint = Paint()
      ..color = const Color(0xFF76FF03).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < totalBlocks; i++) {
      final rect = Rect.fromLTWH(
        i * (blockW + gap),
        0,
        blockW,
        size.height,
      );
      if (i < filledBlocks) {
        canvas.drawRect(rect, glowPaint);
        canvas.drawRect(rect, fillPaint);
      } else {
        canvas.drawRect(rect, bgPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBarPainter old) =>
      old.progress != progress;
}
