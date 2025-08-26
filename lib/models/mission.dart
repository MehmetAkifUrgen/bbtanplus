enum MissionType {
  destroyBricks,
  surviveTime,
  achieveScore,
  destroySpecificBrickType,
}

enum MissionDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionDifficulty difficulty;
  final int targetValue;
  final int rewardPoints;
  final Map<String, dynamic>? additionalData;
  bool isCompleted;
  int currentProgress;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    required this.rewardPoints,
    this.additionalData,
    this.isCompleted = false,
    this.currentProgress = 0,
  });

  double get progressPercentage => 
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  void updateProgress(int value) {
    currentProgress = (currentProgress + value).clamp(0, targetValue);
    if (currentProgress >= targetValue) {
      isCompleted = true;
    }
  }

  void resetProgress() {
    currentProgress = 0;
    isCompleted = false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.index,
    'difficulty': difficulty.index,
    'targetValue': targetValue,
    'rewardPoints': rewardPoints,
    'additionalData': additionalData,
    'isCompleted': isCompleted,
    'currentProgress': currentProgress,
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: MissionType.values[json['type']],
    difficulty: MissionDifficulty.values[json['difficulty']],
    targetValue: json['targetValue'],
    rewardPoints: json['rewardPoints'],
    additionalData: json['additionalData'],
    isCompleted: json['isCompleted'] ?? false,
    currentProgress: json['currentProgress'] ?? 0,
  );
}