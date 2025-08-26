import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import '../models/game_state.dart';

class LevelManager {
  static final LevelManager _instance = LevelManager._internal();
  factory LevelManager() => _instance;
  LevelManager._internal();

  List<Level> _levels = [];
  int _currentLevelIndex = 0;
  int _totalStars = 0;

  List<Level> get levels => _levels;
  Level? get currentLevel => _currentLevelIndex < _levels.length ? _levels[_currentLevelIndex] : null;
  int get currentLevelIndex => _currentLevelIndex;
  int get totalStars => _totalStars;
  int get unlockedLevels => _levels.where((level) => level.isUnlocked).length;

  Future<void> initialize() async {
    await _loadProgress();
    if (_levels.isEmpty) {
      _generateLevels();
      _levels[0].isUnlocked = true; // Unlock first level
      await _saveProgress();
    }
  }

  void _generateLevels() {
    // Generate first 10 levels if empty, more will be generated dynamically
    if (_levels.isEmpty) {
      _levels = [];
      for (int i = 1; i <= 10; i++) {
        _levels.add(_generateLevel(i));
      }
      _levels[0].isUnlocked = true;
    }
  }
  
  Level _generateLevel(int levelNumber) {
    // Calculate dynamic values based on level
    final baseRows = 3 + (levelNumber - 1) ~/ 3; // Increase rows every 3 levels
    final baseCols = 8 + (levelNumber - 1) ~/ 2; // Increase columns every 2 levels
    final maxRows = 12; // Cap at 12 rows
    final maxCols = 20; // Cap at 20 columns
    
    final rows = baseRows > maxRows ? maxRows : baseRows;
    final columns = baseCols > maxCols ? maxCols : baseCols;
    
    // Increase ball count and brick health with level
    final maxBalls = 5 + (levelNumber - 1) * 2; // 2 more balls per level
    final targetScore = 500 + (levelNumber - 1) * 300; // Increase target score
    final baseHitPoints = levelNumber; // Increase hit points every level (more aggressive)
    
    // Determine difficulty based on level
    LevelDifficulty difficulty;
    if (levelNumber <= 5) {
      difficulty = LevelDifficulty.beginner;
    } else if (levelNumber <= 15) {
      difficulty = LevelDifficulty.easy;
    } else if (levelNumber <= 30) {
      difficulty = LevelDifficulty.medium;
    } else if (levelNumber <= 50) {
      difficulty = LevelDifficulty.hard;
    } else {
      difficulty = LevelDifficulty.expert;
    }
    
    return Level(
      levelNumber: levelNumber,
      name: "Level $levelNumber",
      description: "Challenge level $levelNumber",
      difficulty: difficulty,
      rows: rows,
      columns: columns,
      brickLayout: _generateDynamicLayout(rows, columns, levelNumber),
      targetScore: targetScore,
      maxBalls: maxBalls,
      baseHitPoints: baseHitPoints,

      isUnlocked: levelNumber == 1,
    );
  }
  

  
  List<List<BrickType?>> _generateDynamicLayout(int rows, int columns, int levelNumber) {
    // Generate layout based on level number
    if (levelNumber <= 5) {
      return _generateSimpleLayout(rows, columns);
    } else if (levelNumber <= 10) {
      return _generateMixedLayout(rows, columns);
    } else if (levelNumber <= 20) {
      return _generateExplosiveLayout(rows, columns);
    } else if (levelNumber <= 30) {
      return _generateTimeLayout(rows, columns);
    } else {
      return _generateComplexLayout(rows, columns);
    }
  }
  
  // Keep original first level for compatibility
  void _generateOriginalLevels() {
    _levels = [
      Level(
        levelNumber: 1,
        name: "First Steps",
        description: "Learn the basics of Crystal Breaker",
        difficulty: LevelDifficulty.beginner,
        rows: 3,
        columns: 8,
        brickLayout: _generateSimpleLayout(3, 8),
        targetScore: 500,
        maxBalls: 5,
        baseHitPoints: 1,

        isUnlocked: true,
      ),
      Level(
        levelNumber: 2,
        name: "Power Up",
        description: "Discover power-ups",
        difficulty: LevelDifficulty.beginner,
        rows: 4,
        columns: 8,
        brickLayout: _generateMixedLayout(4, 8),
        targetScore: 800,
        maxBalls: 6,
        baseHitPoints: 1,

      ),
      Level(
        levelNumber: 3,
        name: "Explosive Entry",
        description: "Face explosive bricks",
        difficulty: LevelDifficulty.easy,
        rows: 4,
        columns: 10,
        brickLayout: _generateExplosiveLayout(4, 10),
        targetScore: 1200,
        maxBalls: 7,
        baseHitPoints: 2,

      ),
      Level(
        levelNumber: 4,
        name: "Time Warp",
        description: "Master time manipulation",
        difficulty: LevelDifficulty.easy,
        rows: 5,
        columns: 10,
        brickLayout: _generateTimeLayout(5, 10),
        targetScore: 1500,
        maxBalls: 8,
        baseHitPoints: 2,

      ),
      Level(
        levelNumber: 5,
        name: "Teleport Maze",
        description: "Navigate teleporting bricks",
        difficulty: LevelDifficulty.easy,
        rows: 5,
        columns: 12,
        brickLayout: _generateTeleportLayout(5, 12),
        targetScore: 2000,
        maxBalls: 10,
        baseHitPoints: 3,

      ),
      
      // Medium levels (6-10)
      Level(
        levelNumber: 6,
        name: "Mixed Challenge",
        description: "All brick types combined",
        difficulty: LevelDifficulty.medium,
        rows: 6,
        columns: 12,
        brickLayout: _generateComplexLayout(6, 12),
        targetScore: 2500,
        maxBalls: 12,
        baseHitPoints: 3,
        timeLimit: Duration(minutes: 3),

      ),
      Level(
        levelNumber: 7,
        name: "Speed Run",
        description: "Beat the clock",
        difficulty: LevelDifficulty.medium,
        rows: 5,
        columns: 15,
        brickLayout: _generateSpeedLayout(5, 15),
        targetScore: 3000,
        maxBalls: 15,
        baseHitPoints: 4,
        timeLimit: Duration(minutes: 2),

      ),
      Level(
        levelNumber: 8,
        name: "Fortress",
        description: "Break through the fortress",
        difficulty: LevelDifficulty.medium,
        rows: 7,
        columns: 12,
        brickLayout: _generateFortressLayout(7, 12),
        targetScore: 3500,
        maxBalls: 18,
        baseHitPoints: 4,

      ),
      Level(
        levelNumber: 9,
        name: "Chaos Theory",
        description: "Survive the chaos",
        difficulty: LevelDifficulty.hard,
        rows: 8,
        columns: 15,
        brickLayout: _generateChaosLayout(8, 15),
        targetScore: 4000,
        maxBalls: 20,
        baseHitPoints: 5,
        timeLimit: Duration(minutes: 4),

      ),
      Level(
        levelNumber: 10,
        name: "Master Challenge",
        description: "The ultimate test",
        difficulty: LevelDifficulty.expert,
        rows: 10,
        columns: 18,
        brickLayout: _generateMasterLayout(10, 18),
        targetScore: 5000,
        maxBalls: 25,
        baseHitPoints: 5,
        timeLimit: Duration(minutes: 5),

      ),
    ];
  }

  List<List<BrickType?>> _generateSimpleLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) => BrickType.normal));
  }

  List<List<BrickType?>> _generateMixedLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if ((row + col) % 4 == 0) return null; // Some empty spaces
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateExplosiveLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if ((row + col) % 6 == 0) return null;
          if ((row + col) % 3 == 0) return BrickType.explosive;
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateTimeLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if ((row + col) % 8 == 0) return null;
          if (row % 2 == 0 && col % 3 == 0) return BrickType.time;
          if ((row + col) % 4 == 0) return BrickType.explosive;
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateTeleportLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if ((row + col) % 10 == 0) return null;
          if (row == 0 && col % 4 == 0) return BrickType.teleport;
          if (row == rows - 1 && col % 4 == 2) return BrickType.teleport;
          if ((row + col) % 5 == 0) return BrickType.explosive;
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateComplexLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if ((row + col) % 12 == 0) return null;
          if (row % 3 == 0 && col % 3 == 0) return BrickType.teleport;
          if ((row + col) % 4 == 0) return BrickType.explosive;
          if (row % 2 == 1 && col % 4 == 1) return BrickType.time;
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateSpeedLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          if (col % 3 == 1) return null; // More empty spaces for speed
          if (row % 2 == 0) return BrickType.time; // More time bricks
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateFortressLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          // Create fortress walls
          if (row == 0 || row == rows - 1 || col == 0 || col == columns - 1) {
            return BrickType.explosive;
          }
          if (row == 1 || row == rows - 2 || col == 1 || col == columns - 2) {
            return (row + col) % 3 == 0 ? null : BrickType.normal;
          }
          return (row + col) % 4 == 0 ? BrickType.teleport : BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateChaosLayout(int rows, int columns) {
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          final seed = (row * columns + col + random) % 10;
          if (seed == 0) return null;
          if (seed <= 2) return BrickType.explosive;
          if (seed <= 4) return BrickType.time;
          if (seed <= 6) return BrickType.teleport;
          return BrickType.normal;
        }));
  }

  List<List<BrickType?>> _generateMasterLayout(int rows, int columns) {
    return List.generate(rows, (row) => 
        List.generate(columns, (col) {
          // Complex pattern for master level
          if ((row + col) % 15 == 0) return null;
          if (row % 3 == 0 && col % 3 == 0) return BrickType.teleport;
          if ((row - col).abs() % 4 == 0) return BrickType.explosive;
          if ((row + col) % 5 == 0) return BrickType.time;
          return BrickType.normal;
        }));
  }

  void completeLevel(int levelIndex, int score, int ballsUsed, Duration? timeUsed) {
    if (levelIndex >= 0 && levelIndex < _levels.length) {
      final level = _levels[levelIndex];
      final oldStars = level.stars;
      
      level.updateProgress(score, ballsUsed, timeUsed);
      
      // Update total stars
      _totalStars += (level.stars - oldStars);
      
      // Unlock next level if this one is completed
      if (level.isCompleted && levelIndex + 1 < _levels.length) {
        _levels[levelIndex + 1].isUnlocked = true;
      }
      
      _saveProgress();
    }
  }

  void selectLevel(int levelIndex) {
    // Generate more levels if needed
    _ensureLevelExists(levelIndex + 1);
    
    if (levelIndex >= 0 && levelIndex < _levels.length && _levels[levelIndex].isUnlocked) {
      _currentLevelIndex = levelIndex;
    }
  }
  
  void _ensureLevelExists(int levelNumber) {
    while (_levels.length < levelNumber) {
      _levels.add(_generateLevel(_levels.length + 1));
    }
  }
  
  Level? getLevel(int levelNumber) {
    _ensureLevelExists(levelNumber);
    return levelNumber > 0 && levelNumber <= _levels.length ? _levels[levelNumber - 1] : null;
  }

  bool isLevelUnlocked(int levelIndex) {
    return levelIndex >= 0 && levelIndex < _levels.length && _levels[levelIndex].isUnlocked;
  }

  int getRequiredStarsForLevel(int levelIndex) {
    // Require stars to unlock certain levels
    if (levelIndex <= 5) return 0;
    if (levelIndex <= 8) return (levelIndex - 5) * 3;
    return (levelIndex - 5) * 5;
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    final levelsJson = _levels.map((level) => level.toJson()).toList();
    await prefs.setString('levels_progress', jsonEncode(levelsJson));
    await prefs.setInt('current_level_index', _currentLevelIndex);
    await prefs.setInt('total_stars', _totalStars);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    final levelsString = prefs.getString('levels_progress');
    _currentLevelIndex = prefs.getInt('current_level_index') ?? 0;
    _totalStars = prefs.getInt('total_stars') ?? 0;
    
    if (levelsString != null) {
      final levelsJson = jsonDecode(levelsString) as List;
      _levels = levelsJson.map((json) => Level.fromJson(json)).toList();
    }
  }

  void resetProgress() {
    _levels.clear();
    _currentLevelIndex = 0;
    _totalStars = 0;
    _generateLevels();
    _levels[0].isUnlocked = true;
    _saveProgress();
  }
}