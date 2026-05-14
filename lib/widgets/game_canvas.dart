import 'package:dino_game/core/game_state.dart';
import 'package:dino_game/screen/settings_screen.dart';
import 'package:dino_game/widgets/achievement_banner.dart';
import 'package:dino_game/widgets/pause_overlay.dart';
import 'package:dino_game/widgets/trophy_room_screen.dart';
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
            // Determine what overlay to show
            final showStartButtons = provider.gameState == GameState.initial;
            final showPauseButton  = provider.gameState == GameState.playing;
            final showPauseOverlay = provider.isPaused;
            final showBanner = provider.isInitialized &&
                provider.pendingUnlocks.isNotEmpty;

            return Stack(
              children: [

                // ── Layer 1: Game canvas (always present) ─────
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: provider.gameState == GameState.paused
                        ? null
                        : provider.onTap,
                    onLongPressStart: (_) => provider.onDuckStart(),
                    onLongPressEnd:   (_) => provider.onDuckEnd(),
                   
                    
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
                              activeSkin: provider.activeSkin,
                            ),
                          )
                        : const ColoredBox(
                            color: Color(0xFFF7F7F7),
                            child: SizedBox.expand(),
                          ),
                  ),
                ),

                // ── Layer 2: Start screen buttons ─────────────
                // Always show these on the initial screen,
                // regardless of isInitialized — buttons work
                // even before game objects are ready
                if (showStartButtons)
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: _StartScreenButtons(provider: provider),
                  ),

                // ── Layer 3: Pause button ─────────────────────
                if (showPauseButton)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _PauseButton(onTap: provider.togglePause),
                  ),

                // ── Layer 4: Pause overlay ────────────────────
                if (showPauseOverlay)
                  const Positioned.fill(
                    child: PauseOverlay(),
                  ),

                // ── Layer 5: Achievement banner ───────────────
                if (showBanner)
                  Positioned(
                    top: 60,
                    left: 16,
                    right: 16,
                    child: AchievementBanner(
                      achievement: provider.pendingUnlocks.first,
                      onDismissed: () => provider
                          .dismissUnlock(provider.pendingUnlocks.first),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Start screen buttons ───────────────────────────────────────

class _StartScreenButtons extends StatelessWidget {
  final GameProvider provider;
  const _StartScreenButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StartButton(
              icon: Icons.emoji_events_rounded,
              label: 'Trophies',
              color: const Color(0xFFFFD54F),
              onTap: () => _push(context, const TrophyRoomScreen()),
            ),
            const SizedBox(width: 12),
            _StartButton(
              icon: Icons.settings_rounded,
              label: 'Settings',
              color: Colors.white70,
              onTap: () => _push(context, const SettingsScreen()),
            ),
          ],
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: screen,
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StartButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
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

// ── Pause button ───────────────────────────────────────────────

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(
          Icons.pause_rounded,
          color: Colors.white70,
          size: 24,
        ),
      ),
    );
  }
}