import 'package:bbtanpluso3/models/game_state.dart';

import '../components/brick.dart';

enum LevelDifficulty {
  beginner,
  easy,
  medium,
  hard,
  expert,
  master,
}

class Level {
  final int levelNumber;
  final String name;
  final String description;
  final LevelDifficulty difficulty;
  final int rows;
  final int columns;
  final List<List<BrickType?>> brickLayout;
  final int targetScore;
  final int maxBalls;
  final Duration? timeLimit;
  final List<String> availablePowerUps;
  final Map<String, dynamic>? specialRules;
  bool isUnlocked;
  bool isCompleted;
  int bestScore;
  int stars; // 0-3 stars based on performance

  Level({
    required this.levelNumber,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.rows,
    required this.columns,
    required this.brickLayout,
    required this.targetScore,
    required this.maxBalls,
    this.timeLimit,
    required this.availablePowerUps,
    this.specialRules,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestScore = 0,
    this.stars = 0,
  });

  int calculateStars(int score, int ballsUsed, Duration? timeUsed) {
    int earnedStars = 0;
    
    // Base star for completing the level
    if (score >= targetScore) {
      earnedStars = 1;
    }
    
    // Second star for good performance
    if (score >= (targetScore * 1.5).round()) {
      earnedStars = 2;
    }
    
    // Third star for excellent performance
    if (score >= (targetScore * 2).round() && ballsUsed <= (maxBalls * 0.7).round()) {
      earnedStars = 3;
    }
    
    return earnedStars;
  }

  void updateProgress(int score, int ballsUsed, Duration? timeUsed) {
    if (score >= targetScore) {
      isCompleted = true;
    }
    
    if (score > bestScore) {
      bestScore = score;
    }
    
    int newStars = calculateStars(score, ballsUsed, timeUsed);
    if (newStars > stars) {
      stars = newStars;
    }
  }

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'name': name,
    'description': description,
    'difficulty': difficulty.index,
    'rows': rows,
    'columns': columns,
    'brickLayout': brickLayout.map((row) => 
        row.map((brick) => brick?.index).toList()).toList(),
    'targetScore': targetScore,
    'maxBalls': maxBalls,
    'timeLimit': timeLimit?.inSeconds,
    'availablePowerUps': availablePowerUps,
    'specialRules': specialRules,
    'isUnlocked': isUnlocked,
    'isCompleted': isCompleted,
    'bestScore': bestScore,
    'stars': stars,
  };

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    levelNumber: json['levelNumber'],
    name: json['name'],
    description: json['description'],
    difficulty: LevelDifficulty.values[json['difficulty']],
    rows: json['rows'],
    columns: json['columns'],
    brickLayout: (json['brickLayout'] as List).map((row) => 
        (row as List).map((brick) => 
            brick != null ? BrickType.values[brick] : null).toList()).toList(),
    targetScore: json['targetScore'],
    maxBalls: json['maxBalls'],
    timeLimit: json['timeLimit'] != null ? 
        Duration(seconds: json['timeLimit']) : null,
    availablePowerUps: List<String>.from(json['availablePowerUps']),
    specialRules: json['specialRules'],
    isUnlocked: json['isUnlocked'] ?? false,
    isCompleted: json['isCompleted'] ?? false,
    bestScore: json['bestScore'] ?? 0,
    stars: json['stars'] ?? 0,
  );
}