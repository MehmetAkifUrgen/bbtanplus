import 'package:flutter/material.dart';
import '../services/level_manager.dart';
import '../models/level.dart';
import 'game_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late LevelManager levelManager;

  @override
  void initState() {
    super.initState();
    levelManager = LevelManager();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Levels'),
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
              // Progress summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Levels Unlocked',
                      '${levelManager.unlockedLevels}/${levelManager.levels.length}',
                      Icons.lock_open,
                    ),
                    _buildStatItem(
                      'Total Stars',
                      '${levelManager.totalStars}',
                      Icons.star,
                    ),
                    _buildStatItem(
                      'Completed',
                      '${levelManager.levels.where((l) => l.isCompleted).length}',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),
              
              // Levels grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: levelManager.levels.length,
                  itemBuilder: (context, index) {
                    final level = levelManager.levels[index];
                    return _buildLevelCard(level, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.amber,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(Level level, int index) {
    final isUnlocked = level.isUnlocked;
    final isCompleted = level.isCompleted;
    
    return GestureDetector(
      onTap: isUnlocked ? () => _playLevel(level, index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted 
                ? Colors.green.withValues(alpha: 0.5)
                : isUnlocked 
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level number
            Text(
              '${level.levelNumber}',
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Level name
            Text(
              level.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(level.difficulty),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getDifficultyText(level.difficulty),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Stars or lock icon
            if (!isUnlocked)
              const Icon(
                Icons.lock,
                color: Colors.grey,
                size: 20,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (starIndex) {
                  return Icon(
                    starIndex < level.stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            
            // Best score
            if (isUnlocked && level.bestScore > 0) ...
              [
                const SizedBox(height: 4),
                Text(
                  'Best: ${level.bestScore}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.beginner:
        return Colors.lightGreen;
      case LevelDifficulty.easy:
        return Colors.green;
      case LevelDifficulty.medium:
        return Colors.orange;
      case LevelDifficulty.hard:
        return Colors.red;
      case LevelDifficulty.expert:
        return Colors.purple;
      case LevelDifficulty.master:
        return Colors.black;
    }
  }

  String _getDifficultyText(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.beginner:
        return 'BEGINNER';
      case LevelDifficulty.easy:
        return 'EASY';
      case LevelDifficulty.medium:
        return 'MEDIUM';
      case LevelDifficulty.hard:
        return 'HARD';
      case LevelDifficulty.expert:
        return 'EXPERT';
      case LevelDifficulty.master:
        return 'MASTER';
    }
  }

  void _playLevel(Level level, int index) {
    levelManager.selectLevel(index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(selectedLevel: level),
      ),
    );
  }
}