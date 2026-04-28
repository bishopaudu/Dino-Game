import 'package:flutter/material.dart';
import '../widgets/game_canvas.dart';

/// The root screen of the game.
/// 
/// Keeps it simple — full screen canvas with a black background.
/// All UI is drawn inside the canvas by GamePainter.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: GameCanvas(),
      ),
    );
  }
}