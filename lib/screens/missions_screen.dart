import 'package:flutter/material.dart';
import '../services/mission_manager.dart';
import '../models/mission.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  late MissionManager missionManager;

  @override
  void initState() {
    super.initState();
    missionManager = MissionManager();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple, Colors.indigo],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Points display
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Points: ${missionManager.totalPoints}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Active missions
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.amber,
                        tabs: [
                          Tab(text: 'Active Missions'),
                          Tab(text: 'Completed'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMissionsList(missionManager.activeMissions, false),
                            _buildMissionsList(missionManager.completedMissions, true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionsList(List<Mission> missions, bool isCompleted) {
    if (missions.isEmpty) {
      return Center(
        child: Text(
          isCompleted ? 'No completed missions yet' : 'No active missions',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _buildMissionCard(mission, isCompleted);
      },
    );
  }

  Widget _buildMissionCard(Mission mission, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(mission.difficulty),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDifficultyText(mission.difficulty),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          if (!isCompleted) ...
            [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: mission.progressPercentage,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${mission.currentProgress}/${mission.targetValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          
          // Reward
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${mission.rewardPoints} points',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCompleted) ...
                [
                  const Spacer(),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return Colors.green;
      case MissionDifficulty.medium:
        return Colors.orange;
      case MissionDifficulty.hard:
        return Colors.red;
      case MissionDifficulty.expert:
        return Colors.purple;
    }
  }

  String _getDifficultyText(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return 'EASY';
      case MissionDifficulty.medium:
        return 'MEDIUM';
      case MissionDifficulty.hard:
        return 'HARD';
      case MissionDifficulty.expert:
        return 'EXPERT';
    }
  }
}