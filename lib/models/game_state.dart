import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  bool isTimeFrozen = false;
  bool isTimeSlowed = false;
  double timeFreezeRemaining = 0.0;
  double timeSlowRemaining = 0.0;
  
  int score = 0;
  int level = 1;
  int ballsRemaining = 1;
  
  // Additional fields for save/resume functionality
  List<Map<String, dynamic>> brickStates = [];
  Map<String, dynamic>? currentLevelData;
  DateTime? lastSaveTime;
  
  void update(double dt) {
    if (isTimeFrozen) {
      timeFreezeRemaining -= dt;
      if (timeFreezeRemaining <= 0) {
        isTimeFrozen = false;
        timeFreezeRemaining = 0.0;
      }
    }
    
    if (isTimeSlowed) {
      timeSlowRemaining -= dt;
      if (timeSlowRemaining <= 0) {
        isTimeSlowed = false;
        timeSlowRemaining = 0.0;
      }
    }
  }
  
  void activateTimeFreeze(double duration) {
    isTimeFrozen = true;
    timeFreezeRemaining = duration;
  }
  
  void activateTimeSlow(double duration) {
    isTimeSlowed = true;
    timeSlowRemaining = duration;
  }
  
  double getTimeMultiplier() {
    if (isTimeFrozen) return 0.0;
    if (isTimeSlowed) return 0.3;
    return 1.0;
  }
  
  void activateTimeEffect(String effectType, double duration) {
    if (effectType == 'timeFreeze') {
      activateTimeFreeze(duration);
    } else if (effectType == 'timeSlow') {
      activateTimeSlow(duration);
    }
  }
  
  void reset() {
    isTimeFrozen = false;
    isTimeSlowed = false;
    timeFreezeRemaining = 0.0;
    timeSlowRemaining = 0.0;
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
      'isTimeFrozen': isTimeFrozen,
      'isTimeSlowed': isTimeSlowed,
      'timeFreezeRemaining': timeFreezeRemaining,
      'timeSlowRemaining': timeSlowRemaining,
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
      
      isTimeFrozen = gameStateJson['isTimeFrozen'] ?? false;
      isTimeSlowed = gameStateJson['isTimeSlowed'] ?? false;
      timeFreezeRemaining = gameStateJson['timeFreezeRemaining']?.toDouble() ?? 0.0;
      timeSlowRemaining = gameStateJson['timeSlowRemaining']?.toDouble() ?? 0.0;
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
  explosive,
  time,
  teleport,
}