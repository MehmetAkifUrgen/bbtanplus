import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';
import '../models/game_state.dart';

class MissionManager {
  static final MissionManager _instance = MissionManager._internal();
  factory MissionManager() => _instance;
  MissionManager._internal();

  List<Mission> _activeMissions = [];
  List<Mission> _completedMissions = [];
  int _totalPoints = 0;

  List<Mission> get activeMissions => _activeMissions;
  List<Mission> get completedMissions => _completedMissions;
  int get totalPoints => _totalPoints;

  Future<void> initialize() async {
    await _loadMissions();
    if (_activeMissions.isEmpty) {
      _generateInitialMissions();
      await _saveMissions();
    }
  }

  void _generateInitialMissions() {
    _activeMissions = [
      Mission(
        id: 'destroy_100_bricks',
        title: 'Brick Breaker',
        description: 'Destroy 100 bricks',
        type: MissionType.destroyBricks,
        difficulty: MissionDifficulty.easy,
        targetValue: 100,
        rewardPoints: 50,
      ),
      Mission(
        id: 'collect_10_powerups',
        title: 'Power Collector',
        description: 'Collect 10 power-ups',
        type: MissionType.collectPowerUps,
        difficulty: MissionDifficulty.easy,
        targetValue: 10,
        rewardPoints: 30,
      ),
      Mission(
        id: 'score_5000',
        title: 'Score Master',
        description: 'Achieve a score of 5000 points',
        type: MissionType.achieveScore,
        difficulty: MissionDifficulty.medium,
        targetValue: 5000,
        rewardPoints: 75,
      ),
    ];
  }

  void onBrickDestroyed(BrickType brickType) {
    for (var mission in _activeMissions) {
      if (mission.type == MissionType.destroyBricks) {
        mission.updateProgress(1);
      } else if (mission.type == MissionType.destroySpecificBrickType) {
        if (mission.additionalData?['brickType'] == brickType.index) {
          mission.updateProgress(1);
        }
      }
    }
    _checkCompletedMissions();
  }

  void onPowerUpCollected(PowerUpType powerUpType) {
    for (var mission in _activeMissions) {
      if (mission.type == MissionType.collectPowerUps) {
        mission.updateProgress(1);
      } else if (mission.type == MissionType.useSpecificPowerUp) {
        if (mission.additionalData?['powerUpType'] == powerUpType.index) {
          mission.updateProgress(1);
        }
      }
    }
    _checkCompletedMissions();
  }

  void onScoreAchieved(int score) {
    for (var mission in _activeMissions) {
      if (mission.type == MissionType.achieveScore) {
        if (score >= mission.targetValue) {
          mission.currentProgress = mission.targetValue;
          mission.isCompleted = true;
        }
      }
    }
    _checkCompletedMissions();
  }

  void onSurviveTime(Duration duration) {
    for (var mission in _activeMissions) {
      if (mission.type == MissionType.surviveTime) {
        if (duration.inSeconds >= mission.targetValue) {
          mission.currentProgress = mission.targetValue;
          mission.isCompleted = true;
        }
      }
    }
    _checkCompletedMissions();
  }

  void _checkCompletedMissions() {
    var completed = _activeMissions.where((m) => m.isCompleted).toList();
    for (var mission in completed) {
      _completedMissions.add(mission);
      _activeMissions.remove(mission);
      _totalPoints += mission.rewardPoints;
    }
    
    if (completed.isNotEmpty) {
      _generateNewMissions();
      _saveMissions();
    }
  }

  void _generateNewMissions() {
    // Generate new missions based on difficulty progression
    var difficulty = _getDifficultyBasedOnProgress();
    
    while (_activeMissions.length < 3) {
      var newMission = _createRandomMission(difficulty);
      if (!_activeMissions.any((m) => m.id == newMission.id)) {
        _activeMissions.add(newMission);
      }
    }
  }

  MissionDifficulty _getDifficultyBasedOnProgress() {
    if (_totalPoints < 100) return MissionDifficulty.easy;
    if (_totalPoints < 300) return MissionDifficulty.medium;
    if (_totalPoints < 600) return MissionDifficulty.hard;
    return MissionDifficulty.expert;
  }

  Mission _createRandomMission(MissionDifficulty difficulty) {
    var types = MissionType.values;
    var type = types[DateTime.now().millisecondsSinceEpoch % types.length];
    
    switch (type) {
      case MissionType.destroyBricks:
        return Mission(
          id: 'destroy_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Brick Destroyer',
          description: 'Destroy ${_getTargetForDifficulty(difficulty, 50)} bricks',
          type: type,
          difficulty: difficulty,
          targetValue: _getTargetForDifficulty(difficulty, 50),
          rewardPoints: _getRewardForDifficulty(difficulty, 25),
        );
      case MissionType.collectPowerUps:
        return Mission(
          id: 'collect_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Power Hunter',
          description: 'Collect ${_getTargetForDifficulty(difficulty, 5)} power-ups',
          type: type,
          difficulty: difficulty,
          targetValue: _getTargetForDifficulty(difficulty, 5),
          rewardPoints: _getRewardForDifficulty(difficulty, 20),
        );
      case MissionType.achieveScore:
        return Mission(
          id: 'score_${DateTime.now().millisecondsSinceEpoch}',
          title: 'High Scorer',
          description: 'Achieve ${_getTargetForDifficulty(difficulty, 2000)} points',
          type: type,
          difficulty: difficulty,
          targetValue: _getTargetForDifficulty(difficulty, 2000),
          rewardPoints: _getRewardForDifficulty(difficulty, 40),
        );
      default:
        return Mission(
          id: 'survive_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Survivor',
          description: 'Survive for ${_getTargetForDifficulty(difficulty, 60)} seconds',
          type: MissionType.surviveTime,
          difficulty: difficulty,
          targetValue: _getTargetForDifficulty(difficulty, 60),
          rewardPoints: _getRewardForDifficulty(difficulty, 30),
        );
    }
  }

  int _getTargetForDifficulty(MissionDifficulty difficulty, int baseValue) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return baseValue;
      case MissionDifficulty.medium:
        return (baseValue * 1.5).round();
      case MissionDifficulty.hard:
        return (baseValue * 2).round();
      case MissionDifficulty.expert:
        return (baseValue * 3).round();
    }
  }

  int _getRewardForDifficulty(MissionDifficulty difficulty, int baseReward) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return baseReward;
      case MissionDifficulty.medium:
        return (baseReward * 1.5).round();
      case MissionDifficulty.hard:
        return (baseReward * 2).round();
      case MissionDifficulty.expert:
        return (baseReward * 2.5).round();
    }
  }

  Future<void> _saveMissions() async {
    final prefs = await SharedPreferences.getInstance();
    
    final activeMissionsJson = _activeMissions.map((m) => m.toJson()).toList();
    final completedMissionsJson = _completedMissions.map((m) => m.toJson()).toList();
    
    await prefs.setString('active_missions', jsonEncode(activeMissionsJson));
    await prefs.setString('completed_missions', jsonEncode(completedMissionsJson));
    await prefs.setInt('total_points', _totalPoints);
  }

  Future<void> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    
    final activeMissionsString = prefs.getString('active_missions');
    final completedMissionsString = prefs.getString('completed_missions');
    _totalPoints = prefs.getInt('total_points') ?? 0;
    
    if (activeMissionsString != null) {
      final activeMissionsJson = jsonDecode(activeMissionsString) as List;
      _activeMissions = activeMissionsJson.map((json) => Mission.fromJson(json)).toList();
    }
    
    if (completedMissionsString != null) {
      final completedMissionsJson = jsonDecode(completedMissionsString) as List;
      _completedMissions = completedMissionsJson.map((json) => Mission.fromJson(json)).toList();
    }
  }

  void resetAllMissions() {
    _activeMissions.clear();
    _completedMissions.clear();
    _totalPoints = 0;
    _generateInitialMissions();
    _saveMissions();
  }
}