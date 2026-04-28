import 'package:dino_game/screen/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';

void main() {
  runApp(const DinoGameApp());
}

class DinoGameApp extends StatelessWidget {
  const DinoGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider(
        // GameProvider is created at the app root.
        // Any widget below can access it with context.read<GameProvider>()
        create: (_) => GameProvider(),
        child: const GameScreen(),
      ),
    );
  }
}