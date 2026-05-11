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

            // Single GestureDetector wrapping everything.
            // onTap always works regardless of init state.
            return GestureDetector(
              behavior: HitTestBehavior.opaque, // captures taps on empty space too
              onTap: provider.onTap,
              child: provider.isInitialized &&
        provider.dino != null
                  ? CustomPaint(
                      size: size,
                      painter:  GamePainter(
                        dino: provider.dino!,
                        obstacles: provider.obstacles,
                        birds: provider.birds,
                        clouds: provider.clouds,
                        ground: provider.ground,
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
                                                particles: provider.particles,
                                                                        totalTime: provider.totalTime,
                                                                                                sprites: provider.sprites,



                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFF5F5F5),
                      child: SizedBox.expand(),
                    ),
            );
          },
        );
      },
    );
  }
}