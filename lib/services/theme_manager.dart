import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameTheme {
  classic,
  neon,
  space,
  ocean,
  forest,
}

class ThemeManager {
  static const String _themeKey = 'selected_theme';
  GameTheme _currentTheme = GameTheme.classic;
  
  GameTheme get currentTheme => _currentTheme;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _currentTheme = GameTheme.values[themeIndex];
  }
  
  Future<void> setTheme(GameTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
  
  // Theme color schemes
  ThemeColors getThemeColors(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return ThemeColors(
          primary: const Color(0xFF4facfe),
          secondary: const Color(0xFF00f2fe),
          background: const Color(0xFF1a1a2e),
          surface: const Color(0xFF16213e),
          accent: const Color(0xFF0f3460),
          ballColor: Colors.white,
          normalBrick: Colors.blue,
          explosiveBrick: Colors.red,
          timeBrick: Colors.purple,
          teleportBrick: Colors.green,
          powerUpColor: Colors.amber,
        );
      case GameTheme.neon:
        return ThemeColors(
          primary: const Color(0xFFff006e),
          secondary: const Color(0xFF8338ec),
          background: const Color(0xFF000000),
          surface: const Color(0xFF1a0033),
          accent: const Color(0xFF330066),
          ballColor: const Color(0xFF00ffff),
          normalBrick: const Color(0xFFff006e),
          explosiveBrick: const Color(0xFFff4081),
          timeBrick: const Color(0xFF8338ec),
          teleportBrick: const Color(0xFF00ffff),
          powerUpColor: const Color(0xFFffff00),
        );
      case GameTheme.space:
        return ThemeColors(
          primary: const Color(0xFF2d1b69),
          secondary: const Color(0xFF11998e),
          background: const Color(0xFF0c0c0c),
          surface: const Color(0xFF1a1a2e),
          accent: const Color(0xFF16213e),
          ballColor: const Color(0xFFffffff),
          normalBrick: const Color(0xFF2d1b69),
          explosiveBrick: const Color(0xFFe74c3c),
          timeBrick: const Color(0xFF9b59b6),
          teleportBrick: const Color(0xFF11998e),
          powerUpColor: const Color(0xFFf39c12),
        );
      case GameTheme.ocean:
        return ThemeColors(
          primary: const Color(0xFF006994),
          secondary: const Color(0xFF47b5ff),
          background: const Color(0xFF003d5b),
          surface: const Color(0xFF005577),
          accent: const Color(0xFF007aa3),
          ballColor: const Color(0xFFffffff),
          normalBrick: const Color(0xFF006994),
          explosiveBrick: const Color(0xFFe67e22),
          timeBrick: const Color(0xFF3498db),
          teleportBrick: const Color(0xFF1abc9c),
          powerUpColor: const Color(0xFFf1c40f),
        );
      case GameTheme.forest:
        return ThemeColors(
          primary: const Color(0xFF27ae60),
          secondary: const Color(0xFF2ecc71),
          background: const Color(0xFF1e3a2e),
          surface: const Color(0xFF2d5a3d),
          accent: const Color(0xFF3e7b4c),
          ballColor: const Color(0xFFffffff),
          normalBrick: const Color(0xFF27ae60),
          explosiveBrick: const Color(0xFFe74c3c),
          timeBrick: const Color(0xFF8e44ad),
          teleportBrick: const Color(0xFF16a085),
          powerUpColor: const Color(0xFFf39c12),
        );
    }
  }
  
  void refreshGameComponents() {
    // Method to refresh game components when theme changes
    // This can be called after setTheme to update UI components
  }
  
  String getThemeName(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return 'Classic';
      case GameTheme.neon:
        return 'Neon';
      case GameTheme.space:
        return 'Space';
      case GameTheme.ocean:
        return 'Ocean';
      case GameTheme.forest:
        return 'Forest';
    }
  }
  
  String getThemeDescription(GameTheme theme) {
    switch (theme) {
      case GameTheme.classic:
        return 'The original Crystal Breaker experience';
      case GameTheme.neon:
        return 'Bright neon colors for a cyberpunk feel';
      case GameTheme.space:
        return 'Dark cosmic theme with stellar colors';
      case GameTheme.ocean:
        return 'Deep blue oceanic theme';
      case GameTheme.forest:
        return 'Natural green forest theme';
    }
  }
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color accent;
  final Color ballColor;
  final Color normalBrick;
  final Color explosiveBrick;
  final Color timeBrick;
  final Color teleportBrick;
  final Color powerUpColor;
  
  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.accent,
    required this.ballColor,
    required this.normalBrick,
    required this.explosiveBrick,
    required this.timeBrick,
    required this.teleportBrick,
    required this.powerUpColor,
  });
}