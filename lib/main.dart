import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/score_screen.dart';
import 'screens/levels_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/customization_screen.dart';

void main() {
  runApp(const CrystalBreakerApp());
}

class CrystalBreakerApp extends StatelessWidget {
  const CrystalBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCTAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const MainMenuScreen(),
      routes: {
        '/game': (context) => const GameScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/score': (context) => const ScoreScreen(),
        '/levels': (context) => const LevelsScreen(),
        '/missions': (context) => const MissionsScreen(),
        '/customization': (context) => const CustomizationScreen(),
      },
    );
  }
}
