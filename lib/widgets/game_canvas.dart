import 'package:dino_game/core/game_state.dart';
import 'package:dino_game/screen/settings_screen.dart';
import 'package:dino_game/widgets/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../rendering/game_painter.dart';

/// A widget that hosts the game canvas.
/// 
/// Responsibilities:
///   - Measures its own size and passes it to the provider
///   - Detects tap input and forwards it
///   - Renders the GamePainter inside a CustomPaint widget


class GameCanvas extends StatefulWidget {
  const GameCanvas({super.key});

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas>
    with TickerProviderStateMixin {
  bool _initScheduled = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (!_initScheduled && size.width > 0 && size.height > 0) {
          _initScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<GameProvider>().initialize(size, this);
            }
          });
        }

        return Consumer<GameProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                // ── Game canvas ──────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: provider.gameState == GameState.paused
                      ? null           // disable tap-to-jump while paused
                      : provider.onTap,
                  onLongPressStart: (_) => provider.onDuckStart(),
                  onLongPressEnd:   (_) => provider.onDuckEnd(),
                 /* onVerticalDragStart: (d) {
                    if ((d.primaryVelocity ?? 0) > 0) provider.onDuckStart();
                  },*/
                  onVerticalDragEnd: (_) => provider.onDuckEnd(),
                  child: provider.isInitialized && provider.dino != null
                      ? CustomPaint(
                          size: size,
                          painter: GamePainter(
                            dino: provider.dino!,
                            obstacles: provider.obstacles,
                            birds: provider.birds,
                            clouds: provider.clouds,
                            ground: provider.ground,
                            particles: provider.particles,
                            sprites: provider.sprites,
                            groundY: provider.groundY,
                            gameState: provider.gameState,
                            score: provider.score,
                            highScore: provider.highScore,
                            timeOfDay: provider.timeOfDay,
                            flashTimer: provider.flashTimer,
                            shakeMagnitude: provider.shakeMagnitude,
                            isCelebrating: provider.isCelebrating,
                            celebrationOpacity: provider.celebrationOpacity,
                            celebrationScore: provider.celebrationScore,
                            totalTime: provider.totalTime,
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0xFFF7F7F7),
                          child: SizedBox.expand(),
                        ),
                ),

                // ── Pause button (only while playing) ────────
                if (provider.isInitialized &&
                    provider.gameState == GameState.playing)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _PauseButton(
                      onTap: provider.togglePause,
                    ),
                  ),

                // ── Settings button (only on start screen) ───
                /*if (provider.isInitialized &&
                    provider.gameState == GameState.initial)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _IconButton(
                      icon: Icons.settings_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                                  value: provider,
                                  child: const SettingsScreen(),
                                )),
                      ),
                    ),
                  ),*/
                      // ── START SCREEN buttons ──────────────────────
                // Shown only on the initial screen before first game
                if (provider.isInitialized &&
                    provider.gameState == GameState.initial)
                  _StartScreenButtons(provider: provider),

                // ── Pause overlay ─────────────────────────────
                if (provider.isPaused)
                  const PauseOverlay(),
              ],
            );
          },
        );
      },
    );
  }
}

class _StartScreenButtons extends StatelessWidget {
  final GameProvider provider;
  const _StartScreenButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Sits in the lower portion of the screen
      // below the "TAP TO START" text drawn by the painter
      bottom: 60,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Settings button — large enough to tap comfortably
          _StartButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the existing provider down — no new provider needed
        builder: (ctx) => ChangeNotifierProvider.value(
          value: provider,
          child: const SettingsScreen(),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StartButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(
          Icons.pause_rounded,
          color: Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white60, size: 20),
      ),
    );
  }
}