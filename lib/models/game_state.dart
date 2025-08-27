import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  int score = 0;
  int level = 1;
  int ballsRemaining = 1;
  
  // Additional fields for save/resume functionality
  List<Map<String, dynamic>> brickStates = [];
  Map<String, dynamic>? currentLevelData;
  DateTime? lastSaveTime;
  
  void update(double dt) {
    // No time effects to update
  }
  
  double getTimeMultiplier() {
    return 1.0;
  }
  
  void reset() {
    score = 0;
    level = 1;
    ballsRemaining = 1;
    brickStates.clear();
    currentLevelData = null;
    lastSaveTime = null;
  }
  
  // Save game state to SharedPreferences
  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    lastSaveTime = DateTime.now();
    
    final gameStateJson = {
      'score': score,
      'level': level,
      'ballsRemaining': ballsRemaining,
      'brickStates': brickStates,
      'currentLevelData': currentLevelData,
      'lastSaveTime': lastSaveTime?.millisecondsSinceEpoch,
    };
    
    await prefs.setString('saved_game_state', jsonEncode(gameStateJson));
  }
  
  // Load game state from SharedPreferences
  Future<bool> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStateString = prefs.getString('saved_game_state');
    
    if (savedStateString == null) {
      return false;
    }
    
    try {
      final gameStateJson = jsonDecode(savedStateString) as Map<String, dynamic>;
      
      score = gameStateJson['score'] ?? 0;
      level = gameStateJson['level'] ?? 1;
      ballsRemaining = gameStateJson['ballsRemaining'] ?? 1;
      brickStates = List<Map<String, dynamic>>.from(gameStateJson['brickStates'] ?? []);
      currentLevelData = gameStateJson['currentLevelData'];
      
      final lastSaveTimeMs = gameStateJson['lastSaveTime'];
      if (lastSaveTimeMs != null) {
        lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveTimeMs);
      }
      
      return true;
    } catch (e) {
      print('Error loading game state: $e');
      return false;
    }
  }
  
  // Check if there's a saved game
  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('saved_game_state');
  }
  
  // Clear saved game
  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_game_state');
  }
}

enum BrickType {
  normal,
  teleport,
}