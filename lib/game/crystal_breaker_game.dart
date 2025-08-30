import 'dart:math' as math;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../components/ball.dart';
import '../components/brick.dart';
import '../models/game_state.dart';
import '../services/audio_manager.dart';
import '../services/theme_manager.dart';
import '../services/level_manager.dart';
import '../services/mission_manager.dart';
import '../effects/particle_effects.dart';
import '../models/level.dart';

class CrystalBreakerGame extends FlameGame with HasCollisionDetection {
  final Level? selectedLevel;
  Level? currentLevel; // Current level being played
  
  CrystalBreakerGame({this.selectedLevel});
  late GameState gameState;
  Ball? ball;
  List<Ball> balls = []; // Track multiple balls
  List<Brick> bricks = [];
  late AudioManager audioManager;
  late MissionManager missionManager;
  late LevelManager levelManager;
  late ThemeManager themeManager;
  
  Vector2? aimDirection;
  bool isAiming = false;
  bool ballInMotion = false;
  
  int score = 0;
  int level = 1;
  int ballsRemaining = 1;
  
  // Player health and burning system
  int playerLives = 3;
  bool isBurning = false;
  double burnDuration = 0.0;
  double burnDamageTimer = 0.0;
  double burnDamageInterval = 1.0; // Damage every second
  
  // Rewarded ad system for game over
  bool isGameOverState = false;
  bool canWatchAd = true;
  Function? onAdWatched; // Callback for when ad is watched
  
  // Dragon fire attack system removed
  
  // Game constants
  static const double baseBallSpeed = 600.0;
  static const int bricksPerRow = 8; // Fewer bricks for larger size
  
  // Dynamic brick dimensions based on screen size - full width coverage
  double get brickWidth => size.x / bricksPerRow; // No margins, full width
  double get brickHeight => brickWidth * 1.1; // Even taller bricks
  double get brickRowHeight => brickHeight; // No gap between rows
  
  // Dynamic difficulty properties
  double get currentBallSpeed => baseBallSpeed; // Keep ball speed constant
  int get maxBallsPerLevel => (level * 2).clamp(1, 20); // More balls as level increases - 2 balls per level
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize core components first
    gameState = GameState();
    
    // Set current level
    currentLevel = selectedLevel;
    
    // Set up camera
    camera.viewfinder.visibleGameSize = size;
    
    // Initialize managers in parallel for better performance
    await Future.wait([
      _initializeAudio(),
      _initializeManagers(),
    ]);
    
    // Initialize ball with safe theme colors
    ThemeColors currentThemeColors;
    try {
      currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
    } catch (e) {
      // Fallback to default colors if themeManager not ready
      currentThemeColors = const ThemeColors(
        primary: Color(0xFF4facfe),
        secondary: Color(0xFF00f2fe),
        background: Color(0xFF1a1a2e),
        surface: Color(0xFF16213e),
        accent: Color(0xFF0f3460),
        ballColor: Colors.white,
        normalBrick: Colors.blue,
        explosiveBrick: Colors.red,
        timeBrick: Colors.purple,
        teleportBrick: Colors.green,
        powerUpColor: Colors.amber,
      );
    }
    ball = Ball(
      position: Vector2(size.x / 2, size.y - 100),
      speed: currentBallSpeed,
      themeColors: currentThemeColors,
      aimDirection: aimDirection,
    );
    balls.add(ball!);
    add(ball!);
    
    // Generate initial brick layout
    _clearAllBricks(); // Clear any existing bricks first
    _generateBricks();
    
    // Add walls
    _addWalls();
  }
  
  Future<void> _initializeAudio() async {
    audioManager = AudioManager();
    await audioManager.initialize();
    // Don't await background music to speed up loading
    audioManager.playBackgroundMusic();
  }
  
  Future<void> _initializeManagers() async {
    // Initialize managers in parallel
    await Future.wait([
      () async {
        missionManager = MissionManager();
        await missionManager.initialize();
      }(),
      () async {
        levelManager = LevelManager();
        await levelManager.initialize();
      }(),
      () async {
        themeManager = ThemeManager();
        await themeManager.initialize();
      }(),
    ]);
  }
  
  void _addWalls() {
    // Left wall - positioned at screen edge
    final leftWall = RectangleComponent(
      position: Vector2(-1, 100),
      size: Vector2(1, size.y - 100),
      paint: Paint()..color = Colors.transparent,
    );
    leftWall.add(RectangleHitbox());
    add(leftWall);
    
    // Right wall - positioned at screen edge
    final rightWall = RectangleComponent(
      position: Vector2(size.x, 100),
      size: Vector2(1, size.y - 100),
      paint: Paint()..color = Colors.transparent,
    );
    rightWall.add(RectangleHitbox());
    add(rightWall);
    
    // Top wall with visible border - positioned at the same level as bricks start
    final topWall = RectangleComponent(
      position: Vector2(0, 100),
      size: Vector2(size.x, 10),
      paint: Paint()..color = Colors.transparent,
    );
    topWall.add(RectangleHitbox());
    add(topWall);
    
    // No bottom wall - BBTan style (balls fall off screen)
  }
  
  void _generateBricks() {
    final random = Random();
    final currentLevel = levelManager.getLevel(level);
    
    // Calculate responsive brick spacing - full width coverage
    final actualBrickSpacing = size.x / bricksPerRow;
    
    // Use level manager's difficulty settings
    final baseHitPoints = currentLevel?.baseHitPoints ?? 1;
    final brickChance = _getBrickGenerationChance();
    
    // Find the lowest available row to place new bricks
    double newBrickY = _findLowestAvailableRow();
    
    // Generate 1 row of bricks at a time
    for (int row = 0; row < 1; row++) {
      final currentRowY = newBrickY - (row * brickRowHeight);
      
      for (int i = 0; i < bricksPerRow; i++) {
        if (random.nextDouble() < brickChance) {
          // Get theme colors safely
          ThemeColors currentThemeColors;
          try {
            currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
          } catch (e) {
            // Fallback to default colors if themeManager not ready
            currentThemeColors = const ThemeColors(
              primary: Color(0xFF4facfe),
              secondary: Color(0xFF00f2fe),
              background: Color(0xFF1a1a2e),
              surface: Color(0xFF16213e),
              accent: Color(0xFF0f3460),
              ballColor: Colors.white,
              normalBrick: Colors.blue,
              explosiveBrick: Colors.red,
              timeBrick: Colors.purple,
              teleportBrick: Colors.green,
              powerUpColor: Colors.amber,
            );
          }
          
          // Calculate brick position - align to left edge with no gaps
          final brickX = i * brickWidth;
          
          final proposedPosition = Vector2(brickX, currentRowY);
          
          // Check if this position overlaps with existing bricks
          if (!_isPositionOccupied(proposedPosition)) {
            final brick = Brick(
              position: proposedPosition,
              hitPoints: _calculateBrickHitPoints(baseHitPoints, random),
              brickType: _getRandomBrickType(),
              themeColors: currentThemeColors,
              customSize: Vector2(brickWidth, brickHeight), // Pass responsive size
            );
            bricks.add(brick);
            add(brick);
          }
        }
      }
    }
  }
  
  double _findLowestAvailableRow() {
    // BBTan style: Always generate new bricks from the top
    double startY = 100; // Below top wall
    
    // Always return the top position for new bricks
    return startY;
  }
  
  bool _isPositionOccupied(Vector2 position) {
    const double tolerance = 5.0; // Small tolerance for position checking
    
    for (final existingBrick in bricks) {
      final distance = (existingBrick.position - position).length;
      if (distance < (brickWidth / 2 + tolerance)) {
        return true; // Position is too close to existing brick
      }
    }
    return false;
  }
  
  void _shiftBricksDown(double shiftAmount) {
    // Shift all existing bricks down by the specified amount
    for (final brick in bricks) {
      brick.position.y += shiftAmount;
      
      // If any brick goes below the danger zone, trigger game over
      if (brick.position.y > size.y - 200) {
        if (!isBurning) {
          startBurning(5.0);
        }
      }
    }
  }
  
  void _clearAllBricks() {
    // Only use this for game initialization
    for (final brick in bricks) {
      brick.removeFromParent();
    }
    bricks.clear();
  }
  
  BrickType _getRandomBrickType() {
    final random = Random();
    final chance = random.nextDouble();
    
    // Increase special brick chances with level progression
    final teleportChance = 0.08 + (level * 0.01); // Start at 8%, increase 1% per level
    
    if (chance < teleportChance) {
      return BrickType.teleport;
    } else {
      return BrickType.normal;
    }
  }
  
  double _getBrickGenerationChance() {
    // Start with 80% chance, increase more aggressively with level
    return (0.8 + (level * 0.02)).clamp(0.8, 0.95);
  }
  
  int _calculateBrickHitPoints(int baseHitPoints, Random random) {
    // Increase difficulty: base hit points grow with both ballsRemaining and current level
    // Add baseHitPoints from LevelManager for extra scaling
    final int difficultyBase = ballsRemaining + (level ~/ 2) + baseHitPoints;

    // Allow 20% random variation around the calculated base
    final int variation = (difficultyBase * 0.2).round();
    final int minHitPoints = (difficultyBase - variation).clamp(1, difficultyBase);
    final int maxHitPoints = difficultyBase + variation;

    return random.nextInt(maxHitPoints - minHitPoints + 1) + minHitPoints;
  }
  
  // -------------------
  // Persistence Helpers
  // -------------------
  
  /// Capture the current in-memory game parameters and brick layout into [gameState]
  void captureGameState() {
    gameState.score = score;
    gameState.level = level;
    gameState.ballsRemaining = ballsRemaining;
    gameState.brickStates = bricks.map((brick) => {
          'x': brick.position.x,
          'y': brick.position.y,
          'hitPoints': brick.hitPoints,
          'maxHitPoints': brick.maxHitPoints,
          'brickType': brick.brickType.toString().split('.').last,
        }).toList();
  }

  /// Restore bricks and key counters from a previously saved [state].
  void restoreFromGameState(GameState state) {
    score = state.score;
    level = state.level;
    ballsRemaining = state.ballsRemaining;

    // Clear any existing bricks to avoid duplicates
    _clearAllBricks();

    for (final brickJson in state.brickStates) {
      final brickTypeStr = brickJson['brickType'] as String? ?? 'normal';
      final brickType = _brickTypeFromString(brickTypeStr);
      
      // Get theme colors safely - use default if themeManager not initialized
      ThemeColors currentThemeColors;
      try {
        currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
      } catch (e) {
        // Fallback to default colors if themeManager not ready
        currentThemeColors = const ThemeColors(
          primary: Color(0xFF4facfe),
          secondary: Color(0xFF00f2fe),
          background: Color(0xFF1a1a2e),
          surface: Color(0xFF16213e),
          accent: Color(0xFF0f3460),
          ballColor: Colors.white,
          normalBrick: Colors.blue,
          explosiveBrick: Colors.red,
          timeBrick: Colors.purple,
          teleportBrick: Colors.green,
          powerUpColor: Colors.amber,
        );
      }
      
      final brick = Brick(
        position: Vector2((brickJson['x'] as num).toDouble(), (brickJson['y'] as num).toDouble()),
        hitPoints: brickJson['hitPoints'] ?? 1,
        brickType: brickType,
        themeColors: currentThemeColors,
        customSize: Vector2(brickWidth, brickHeight),
      );
      brick.maxHitPoints = brickJson['maxHitPoints'] ?? brick.hitPoints;
      bricks.add(brick);
      add(brick);
    }
  }

  BrickType _brickTypeFromString(String type) {
    switch (type) {
      case 'teleport':
        return BrickType.teleport;
      default:
        return BrickType.normal;
    }
  }
  
  /// Apply difficulty settings for the current [level].
  /// Currently this just acts as a hook for future balancing tweaks
  /// such as ball speed escalation or power-up frequency.
  void _applyLevelDifficulty() {
    final currentLevel = levelManager.getLevel(level);
    if (currentLevel != null) {
      // Difficulty scaling is mostly achieved via brick generation for now.
      // Add additional per-level balancing here when necessary.
    }
  }
  
  // Public methods for handling input from game screen
  void startAiming(Offset tapPosition) {
    if (!ballInMotion && ball != null) {
      isAiming = true;
      _updateAimDirection(tapPosition);
    }
  }
  
  void updateAiming(Offset tapPosition) {
    if (isAiming && !ballInMotion && ball != null) {
      _updateAimDirection(tapPosition);
    }
  }
  
  void _updateAimDirection(Offset tapPosition) {
    final worldPosition = Vector2(tapPosition.dx, tapPosition.dy);
    final ballPosition = ball!.position;
    
    // Calculate direction vector
    Vector2 direction = (worldPosition - ballPosition);
    
    // Prevent zero vector
    if (direction.length < 1.0) {
      direction = Vector2(0, -1);
    } else {
      direction.normalize();
    }
    
    // Restrict aiming to upward direction only (y must be negative)
    if (direction.y >= 0) {
      // If trying to aim downward, set to straight up
      direction = Vector2(0, -1);
    }
    
    // Ensure minimum upward angle (at least 15 degrees from horizontal)
    final minUpwardY = -0.25; // sin(15°) ≈ 0.25
    if (direction.y > minUpwardY) {
      // Adjust to minimum upward angle while preserving horizontal direction
      final horizontalSign = direction.x >= 0 ? 1.0 : -1.0;
      direction = Vector2(horizontalSign * 0.97, minUpwardY).normalized();
    }
    
    aimDirection = direction;
    
    // Update ball's aim direction for barrel rotation
    if (ball != null) {
      ball!.updateAimDirection(aimDirection);
    }
  }
  
  void launchBall() {
    if (isAiming && aimDirection != null && ball != null) {
      _launchBall();
      isAiming = false;
    }
  }
  
  void _launchBall() {
    if (aimDirection != null && ball != null) {
      // Store the aim direction to prevent null reference in delayed callbacks
      final launchDirection = aimDirection!;
      
      // Launch the first ball immediately
      ball!.launch(launchDirection);
      
      // Launch additional balls with delay for BBTan style
      for (int i = 1; i < ballsRemaining; i++) {
        // Create additional balls with safe theme colors
        ThemeColors currentThemeColors;
        try {
          currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
        } catch (e) {
          // Fallback to default colors if themeManager not ready
          currentThemeColors = const ThemeColors(
            primary: Color(0xFF4facfe),
            secondary: Color(0xFF00f2fe),
            background: Color(0xFF1a1a2e),
            surface: Color(0xFF16213e),
            accent: Color(0xFF0f3460),
            ballColor: Colors.white,
            normalBrick: Colors.blue,
            explosiveBrick: Colors.red,
            timeBrick: Colors.purple,
            teleportBrick: Colors.green,
            powerUpColor: Colors.amber,
          );
        }
        final newBall = Ball(
          position: Vector2(size.x / 2, size.y - 100),
          speed: currentBallSpeed,
          themeColors: currentThemeColors,
          aimDirection: aimDirection,
        );
        balls.add(newBall);
        add(newBall);
        
        // Launch ball with slight delay for visual effect
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (newBall.isMounted) {
            newBall.launch(launchDirection);
          }
        });
      }
      
      ballInMotion = true;
      aimDirection = null;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update game state (time effects)
    gameState.update(dt);
    
    // Update burning effect
    _updateBurningEffect(dt);
    
    // Update dragon movements only (fire attacks removed)
    _updateDragons(dt);
    
    // Check if all balls have returned to bottom
    _checkBallsReturned();
    
    // Check for game over conditions
    _checkGameOver();
    

  }
  
  void _checkBallsReturned() {
    // Remove balls that have fallen off screen (except main ball)
    balls.removeWhere((ballToCheck) {
      if (ballToCheck.position.y > size.y + 50) {
        if (ballToCheck != ball) {
          ballToCheck.removeFromParent();
          return true;
        } else {
          // Reset main ball position if it falls off screen
          ballToCheck.position = Vector2(size.x / 2, size.y - 100);
          ballToCheck.stop();
        }
      }
      return false;
    });
    
    // Check if all balls are at rest at bottom
    bool allBallsReturned = true;
    for (final ballToCheck in balls) {
      if (ballToCheck.position.y < size.y - 150 || ballToCheck.velocity.length > 10) {
        allBallsReturned = false;
        break;
      }
    }
    
    if (allBallsReturned && ballInMotion && balls.isNotEmpty) {
      _allBallsReturned();
    }
  }
  
  void _allBallsReturned() {
    ballInMotion = false;
    
    // Reset all balls to main ball position
    final ballsToRemove = <Ball>[];
    for (final ballToCheck in balls) {
      if (ballToCheck != ball) {
        ballsToRemove.add(ballToCheck);
      }
    }
    
    // Remove extra balls
    for (final ballToRemove in ballsToRemove) {
      ballToRemove.removeFromParent();
      balls.remove(ballToRemove);
    }
    
    // Ensure main ball is in the list and positioned correctly
    if (ball != null) {
      if (!balls.contains(ball!)) {
        balls.add(ball!);
      }
      ball!.stop();
      ball!.position = Vector2(size.x / 2, size.y - 100);
    }
    
    // Move bricks down
    _moveBricksDown();
    
    // Always generate new row of bricks (BBTan style)
    _generateBricks();
    
    // Increase ball count for next round (BBTan style) - faster growth
    if (ballsRemaining < maxBallsPerLevel) {
      ballsRemaining += 2; // Increase by 2 balls each round instead of 1
      if (ballsRemaining > maxBallsPerLevel) {
        ballsRemaining = maxBallsPerLevel;
      }
    }
    level++;

    // Sync game state ball count for correct persistence
    gameState.ballsRemaining = ballsRemaining;
    
    // Update level manager and apply difficulty progression
    levelManager.selectLevel(level - 1); // level-1 because level is 1-indexed
    _applyLevelDifficulty();

    // Capture snapshot for automatic persistence after each round
    captureGameState();
    
    // Automatically save game state after each ball throw
    gameState.saveGameState().catchError((error) {
      print('Error auto-saving game state: $error');
    });
  }
  
  void _moveBricksDown() {
    // Calculate how many rows to move down based on level
    double moveDistance = brickRowHeight;
    
    // At higher levels, bricks move down faster (2 rows at once)
    if (level >= 10) {
      moveDistance = brickRowHeight * 2; // Move 2 rows at once
    } else if (level >= 5) {
      // 50% chance to move 2 rows at levels 5-9
      if (Random().nextDouble() < 0.5) {
        moveDistance = brickRowHeight * 2;
      }
    }
    
    for (final brick in bricks) {
      brick.position.y += moveDistance;
    }
  }
  
  void _updateBurningEffect(double dt) {
    if (isBurning) {
      burnDuration -= dt;
      burnDamageTimer += dt;
      
      // Deal damage every second while burning
      if (burnDamageTimer >= burnDamageInterval) {
        _takeDamage();
        burnDamageTimer = 0.0;
      }
      
      // Stop burning after duration expires
      if (burnDuration <= 0) {
        isBurning = false;
        burnDuration = 0.0;
        burnDamageTimer = 0.0;
      }
    }
  }
  
  void _takeDamage() {
    playerLives--;
    
    // Play damage sound
    audioManager.playSound('player_damage');
    
    // Check if player is dead
    if (playerLives <= 0) {
      gameOver();
    }
  }
  
  void startBurning(double duration) {
    isBurning = true;
    burnDuration = duration;
    burnDamageTimer = 0.0;
  }
  
  void _updateDragons(double dt) {
    for (final brick in bricks) {
      if (brick.isDragon) {
        brick.update(dt);
      }
    }
  }
  
  // Dragon fire attack methods removed
  
  void _checkGameOver() {
    // Check if any brick has reached the tank level
    for (final brick in bricks) {
      if (brick.position.y > size.y - 150) {
        // Start burning effect when bricks reach player
        if (!isBurning && !isGameOverState) {
          startBurning(5.0); // Burn for 5 seconds
          isGameOverState = true;
          
          // Pause the game and show rewarded ad option
          pauseEngine();
          
          // Trigger rewarded ad callback if available
          if (canWatchAd && onAdWatched != null) {
            onAdWatched!();
          } else {
            // If no ad system available, just game over
            gameOver();
          }
        }
        return;
      }
    }
  }
  
  void gameOver() {
    // Notify mission manager of final score
    missionManager.onScoreAchieved(score);
    
    // Complete current level in level manager
    levelManager.completeLevel(
      levelManager.currentLevelIndex, 
      score, 
      ballsRemaining, 
      null // Duration would be tracked separately
    );
    
    // Play game over sound
    audioManager.playSound('game_over');
    
    // Handle game over logic
    pauseEngine();
    // Navigate to score screen with current score
    // This would be handled by the parent widget
  }

  // Function to remove ONLY the bottom-most brick row after watching ad
  void removeBottomBrickRow() {
    print('removeBottomBrickRow called');
    print('Total bricks before removal: ${bricks.length}');
    
    if (bricks.isEmpty) {
      print('No bricks to remove');
      return;
    }

    // Helper to map a brick to its row index (top wall starts at y = 100)
    const double topWallY = 100;
    int _rowIndex(Brick b) => ((b.position.y - topWallY) / brickRowHeight).floor();

    // Player level (same as _checkGameOver threshold)
    final double playerLevel = size.y - 150;
    print('Player level: $playerLevel');
    print('Brick row height: $brickRowHeight');

    // Print all brick positions for debugging
    print('All brick positions:');
    for (int i = 0; i < bricks.length; i++) {
      print('  Brick $i: Y=${bricks[i].position.y.toStringAsFixed(2)}');
    }

    // Always target the bottom-most row (highest Y value)
    double targetRowY = bricks
        .map((brick) => brick.position.y)
        .reduce((a, b) => a > b ? a : b);
    
    print('Always targeting bottom-most row (highest Y)');
    print('Bottom-most Y found: ${targetRowY.toStringAsFixed(2)}');

    print('Target row Y: ${targetRowY.toStringAsFixed(2)}');

    const double tolerance = 1.0; // full row height tolerance
    final toleranceValue = brickRowHeight * tolerance;
    print('Tolerance value: ${toleranceValue.toStringAsFixed(2)}');
    
    final bricksToRemove = bricks
         .where((brick) {
           final distance = (brick.position.y - targetRowY).abs();
           final shouldRemove = distance <= toleranceValue;
           print('  Brick Y=${brick.position.y.toStringAsFixed(2)}, distance=${distance.toStringAsFixed(2)}, remove=$shouldRemove');
           return shouldRemove;
         })
         .toList();

    print('Bricks to remove: ${bricksToRemove.length}');

    for (final brick in bricksToRemove) {
      print('  Removing brick at Y=${brick.position.y.toStringAsFixed(2)}');
      brick.destroy(); // Use destroy() method instead of manual removal
    }

    print('Total bricks after removal: ${bricks.length}');

    // Reset burning/game-over state and resume play
    isGameOverState = false;
    isBurning = false;
    burnDuration = 0.0;
    burnDamageTimer = 0.0;
    canWatchAd = false;

    // Check if there are still bricks at player level after removal
    bool stillGameOver = false;
    for (final brick in bricks) {
      if (brick.position.y > playerLevel) {
        stillGameOver = true;
        print('Warning: Brick still at player level Y=${brick.position.y.toStringAsFixed(2)}');
        break;
      }
    }

    if (stillGameOver) {
      print('Game still over - bricks still at player level');
      // Don't resume, keep game paused
    } else {
      print('All bricks cleared from player level - resuming game');
      resumeEngine();
    }
    
    print('Game states reset: isGameOverState=false, isBurning=false, canWatchAd=false');
    print('Bottom row removed! Removed ${bricksToRemove.length} bricks.');
    print('Still game over: $stillGameOver');
  }

  void refreshTheme() {
    final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
    
    // Update ball colors
    for (final ball in balls) {
      ball.themeColors = currentThemeColors;
      ball.originalColor = currentThemeColors.ballColor;
      if (!ball.isLaserMode) {
        ball.paint.color = currentThemeColors.ballColor;
      }
    }
    
    // Update brick colors
    for (final brick in bricks) {
      brick.themeColors = currentThemeColors;
      brick.updateAppearance();
    }
    

  }
  
  void onBrickDestroyed(Brick brick) {
    // Use original hit points to ensure proper score calculation
    score += brick.maxHitPoints * 10;
    bricks.remove(brick);
    
    // Notify mission manager
    missionManager.onBrickDestroyed(brick.brickType);
    
    // Play brick break sound
    audioManager.playSound('brick_break');
    
    // Add particle effect
    final particleEffect = ParticleEffects.createBrickBreakEffect(brick.position);
    add(particleEffect);
    
    // Handle special brick effects
    switch (brick.brickType) {
      case BrickType.teleport:
        _teleportBrick(brick);
        break;
      case BrickType.normal:
        break;
    }
    

  }
  

  
  void _teleportBrick(Brick brick) {
    final random = Random();
    final brickMargin = 10.0;
    
    // Ensure teleported brick stays within screen bounds
    final safeX = brickMargin + random.nextDouble() * (size.x - 2 * brickMargin - brickWidth);
    final safeY = 120 + random.nextDouble() * (size.y / 2 - 120); // Stay below UI and above bottom half
    
    brick.position = Vector2(safeX, safeY);
  }
  

  

  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw game borders (BBTan style)
    _drawGameBorders(canvas);
    
    // Draw aim line when aiming
    if (isAiming && aimDirection != null) {
      _drawAimLine(canvas);
    }
  }
  
  void _drawGameBorders(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    
    // Draw shadow first (behind the main border)
    canvas.drawLine(
      const Offset(1, 100),
      Offset(1, size.y),
      shadowPaint,
    );
    
    canvas.drawLine(
      Offset(size.x - 1, 100),
      Offset(size.x - 1, size.y),
      shadowPaint,
    );
    
    canvas.drawLine(
      const Offset(0, 101),
      Offset(size.x, 101),
      shadowPaint,
    );
    
    // Draw main borders
    // Left border
    canvas.drawLine(
      const Offset(0, 100),
      Offset(0, size.y),
      borderPaint,
    );
    
    // Right border
    canvas.drawLine(
      Offset(size.x, 100),
      Offset(size.x, size.y),
      borderPaint,
    );
    
    // Top border
    canvas.drawLine(
      const Offset(0, 100),
      Offset(size.x, 100),
      borderPaint,
    );
    
    // Add corner highlights for better visibility
    final cornerPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Top-left corner
    canvas.drawLine(
      const Offset(0, 100),
      const Offset(20, 100),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(0, 100),
      const Offset(0, 120),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(size.x - 20, 100),
      Offset(size.x, 100),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.x, 100),
      Offset(size.x, 120),
      cornerPaint,
    );
    
    // No bottom corners - BBTan style (open bottom)
  }
  
  void _drawAimLine(Canvas canvas) {
    if (aimDirection == null || ball == null) return;
    
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    
    final start = ball!.position;
    final direction = aimDirection!.normalized();
    
    // Draw dotted line with trajectory prediction (BBTan style)
    const double dotSpacing = 15.0;
    const double dotRadius = 2.0;
    const int maxDots = 30;
    
    Vector2 currentPos = start.clone();
    Vector2 velocity = direction * currentBallSpeed;
    
    for (int i = 0; i < maxDots; i++) {
      // Draw dot
      canvas.drawCircle(
        Offset(currentPos.x, currentPos.y),
        dotRadius,
        paint,
      );
      
      // Simulate ball physics for next dot position
      currentPos += velocity * (dotSpacing / currentBallSpeed);
      
      // Check wall bounces
      if (currentPos.x <= 12 || currentPos.x >= size.x - 12) {
        velocity.x = -velocity.x;
        currentPos.x = currentPos.x <= 12 ? 12 : size.x - 12;
      }
      
      if (currentPos.y <= 112) {
        velocity.y = -velocity.y;
        currentPos.y = 112;
      }
      
      // Stop if ball goes too far down or hits a brick
      if (currentPos.y > size.y - 100) break;
      
      // Check brick collision
      bool hitBrick = false;
      for (final brick in bricks) {
        final brickRect = Rect.fromLTWH(
          brick.position.x - brick.size.x / 2,
          brick.position.y - brick.size.y / 2,
          brick.size.x,
          brick.size.y,
        );
        
        if (brickRect.contains(Offset(currentPos.x, currentPos.y))) {
          hitBrick = true;
          break;
        }
      }
      
      if (hitBrick) break;
      
      // Fade out dots as they get further
      paint.color = Colors.white.withValues(alpha: 0.8 - (i * 0.02));
    }
  }
}