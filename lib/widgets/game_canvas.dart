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
    with TickerProviderStateMixin {  // Provides vsync for the Ticker
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Initialize the game once we know the canvas size.
        // LayoutBuilder can be called multiple times, so guard with a flag.
        if (!_initialized) {
          _initialized = true;
          // Schedule after build to avoid calling setState during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<GameProvider>().initialize(size, this);
          });
        }

        return GestureDetector(
          // Forward taps to the game (jump or start/restart).
          onTap: () => context.read<GameProvider>().onTap(),
          child: Consumer<GameProvider>(
            builder: (context, provider, _) {
              // If not yet initialized, show a blank loading state.
              if (!_initialized || provider.gameState == null) {
                return const SizedBox.expand();
              }

              return CustomPaint(
                size: size,
                painter: GamePainter(
                  dino: provider.dino,
                  obstacles: provider.obstacles,
                  groundY: provider.groundY,
                  gameState: provider.gameState,
                  score: provider.score,
                ),
              );
            },
          ),
        );
      },
    );
  }
}