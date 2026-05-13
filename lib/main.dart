import 'package:dino_game/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // flutter_native_splash — must be called before ensureInitialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock to portrait — running games in landscape is disorienting
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full immersive mode — hide status bar and nav bar
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Remove the native OS splash and hand off to our Flutter splash screen
  FlutterNativeSplash.remove();

  runApp(const DinoGameApp());
}

class DinoGameApp extends StatelessWidget {
  const DinoGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      // SplashScreen navigates to GameScreen once its animation completes
      home: const SplashScreen(),
    );
  }
}