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
  late List<Brick> bricks;
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
  
  // Dragon fire attack system removed
  
  // Game constants
  static const double baseBallSpeed = 600.0;
  static const double brickRowHeight = 45.0; // Reduced for tighter spacing
  static const double brickWidth = 60.0; // Match brick component size
  static const double brickHeight = 35.0; // Match brick component size
  static const int bricksPerRow = 9; // Increased to fit more characters
  
  // Dynamic difficulty properties
  double get currentBallSpeed => baseBallSpeed; // Keep ball speed constant
  int get maxBallsPerLevel => (level * 2).clamp(1, 20); // More balls as level increases - 2 balls per level
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize core components first
    gameState = GameState();
    bricks = [];
    
    // Set current level
    currentLevel = selectedLevel;
    
    // Set up camera
    camera.viewfinder.visibleGameSize = size;
    
    // Initialize managers in parallel for better performance
    await Future.wait([
      _initializeAudio(),
      _initializeManagers(),
    ]);
    
    // Initialize ball with theme colors
    final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
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
    // Left wall with visible border
    final leftWall = RectangleComponent(
      position: Vector2(-10, 100),
      size: Vector2(10, size.y - 100),
      paint: Paint()..color = Colors.transparent,
    );
    leftWall.add(RectangleHitbox());
    add(leftWall);
    
    // Right wall with visible border
    final rightWall = RectangleComponent(
      position: Vector2(size.x, 100),
      size: Vector2(10, size.y - 100),
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
    
    // Calculate safe boundaries for bricks with tighter spacing
    final brickMargin = 10.0; // Reduced margin from screen edges
    final availableWidth = size.x - (2 * brickMargin);
    final brickSpacing = availableWidth / bricksPerRow;
    final minBrickSpacing = brickWidth + 2.0; // Minimum 2px gap between bricks
    final actualBrickSpacing = math.max(brickSpacing, minBrickSpacing);
    
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
          final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
          
          // Calculate brick position with proper boundaries and spacing
          final brickX = brickMargin + (i * actualBrickSpacing) + (actualBrickSpacing / 2);
          
          // Ensure brick stays within screen bounds
          final clampedX = brickX.clamp(brickMargin + (brickWidth / 2), 
                                       size.x - brickMargin - (brickWidth / 2));
          
          final proposedPosition = Vector2(clampedX, currentRowY);
          
          // Check if this position overlaps with existing bricks
          if (!_isPositionOccupied(proposedPosition)) {
            final brick = Brick(
              position: proposedPosition,
              hitPoints: _calculateBrickHitPoints(baseHitPoints, random),
              brickType: _getRandomBrickType(),
              themeColors: currentThemeColors,
            );
            bricks.add(brick);
            add(brick);
          }
        }
      }
    }
  }
  
  double _findLowestAvailableRow() {
    // Start from the top and find the first available row
    double startY = 100; // Below top wall
    
    // If no bricks exist, start at the top
    if (bricks.isEmpty) {
      return startY;
    }
    
    // Find the topmost brick position
    double topmostY = bricks.map((brick) => brick.position.y).reduce((a, b) => a < b ? a : b);
    
    // Calculate new position above the topmost existing brick
    double newY = topmostY - brickRowHeight;
    
    // Ensure bricks don't go above the top boundary (100px from top)
    if (newY < startY) {
      // If bricks would go above boundary, shift all existing bricks down
      _shiftBricksDown(startY - newY);
      return startY;
    }
    
    return newY;
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
    final explosiveChance = 0.05 + (level * 0.01); // Start at 5%, increase 1% per level
    final timeChance = explosiveChance + 0.03 + (level * 0.005); // Start at 8%, increase 0.5% per level
    final teleportChance = timeChance + 0.03 + (level * 0.005); // Start at 11%, increase 0.5% per level
    
    if (chance < explosiveChance) {
      return BrickType.explosive;
    } else if (chance < timeChance) {
      return BrickType.time;
    } else if (chance < teleportChance) {
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
    // Calculate hit points based on current ball count (level)
    // Brick values should match the number of balls player has
    final targetHitPoints = ballsRemaining;
    
    // Add some variation (±1) but keep it close to ball count
    final minHitPoints = (targetHitPoints - 1).clamp(1, targetHitPoints);
    final maxHitPoints = targetHitPoints + 1;
    
    return random.nextInt(maxHitPoints - minHitPoints + 1) + minHitPoints;
  }
  
  void _applyLevelDifficulty() {
    final currentLevel = levelManager.getLevel(level);
    if (currentLevel != null) {
      // Apply level-specific difficulty settings
      // This could include adjusting ball speed, power-up chances, etc.
      // For now, the difficulty is mainly handled through brick generation
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
        // Create additional balls
        final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
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
    
    // Update level manager and apply difficulty progression
    levelManager.selectLevel(level - 1); // level-1 because level is 1-indexed
    _applyLevelDifficulty();
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
      _gameOver();
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
        if (!isBurning) {
          startBurning(5.0); // Burn for 5 seconds
        }
        return;
      }
    }
  }
  
  void _gameOver() {
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
    score += brick.hitPoints * 10;
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
      case BrickType.explosive:
        _explodeBrick(brick);
        break;
      case BrickType.time:
        _activateTimeSlow();
        break;
      case BrickType.teleport:
        _teleportBrick(brick);
        break;
      case BrickType.normal:
        break;
    }
    

  }
  
  void _explodeBrick(Brick brick) {
    final explosionRadius = 100.0;
    final bricksToDestroy = <Brick>[];
    
    // Add explosion particle effect
    final explosionEffect = ParticleEffects.createExplosionEffect(brick.position);
    add(explosionEffect);
    
    for (final otherBrick in bricks) {
      if (otherBrick != brick) {
        final distance = brick.position.distanceTo(otherBrick.position);
        if (distance <= explosionRadius) {
          bricksToDestroy.add(otherBrick);
        }
      }
    }
    
    for (final brickToDestroy in bricksToDestroy) {
      brickToDestroy.destroy();
    }
  }
  
  void _activateTimeSlow() {
    // Implement time slow effect
    gameState.activateTimeSlow(3.0); // 3 seconds
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