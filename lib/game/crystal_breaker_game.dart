import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../components/ball.dart';
import '../components/brick.dart';
import '../components/power_up.dart';
import '../models/game_state.dart';
import '../services/audio_manager.dart';
import '../services/mission_manager.dart';
import '../services/level_manager.dart';
import '../services/theme_manager.dart';
import '../effects/particle_effects.dart';
import '../models/level.dart';

class CrystalBreakerGame extends FlameGame with HasCollisionDetection {
  final Level? selectedLevel;
  
  CrystalBreakerGame({this.selectedLevel});
  late GameState gameState;
  Ball? ball;
  List<Ball> balls = []; // Track multiple balls
  late List<Brick> bricks;
  late List<PowerUp> powerUps;
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
  
  // Game constants
  static const double ballSpeed = 600.0;
  static const double brickRowHeight = 60.0;
  static const double brickWidth = 80.0;
  static const double brickHeight = 50.0;
  static const int bricksPerRow = 7;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize core components first
    gameState = GameState();
    bricks = [];
    powerUps = [];
    
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
      speed: ballSpeed,
      themeColors: currentThemeColors,
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
    // Left wall
    final leftWall = RectangleComponent(
      position: Vector2(-10, 0),
      size: Vector2(10, size.y),
    );
    leftWall.add(RectangleHitbox());
    add(leftWall);
    
    // Right wall
    final rightWall = RectangleComponent(
      position: Vector2(size.x, 0),
      size: Vector2(10, size.y),
    );
    rightWall.add(RectangleHitbox());
    add(rightWall);
    
    // Top wall
    final topWall = RectangleComponent(
      position: Vector2(0, -10),
      size: Vector2(size.x, 10),
    );
    topWall.add(RectangleHitbox());
    add(topWall);
  }
  
  void _generateBricks() {
    final random = Random();
    
    // Generate new row of bricks at the top (BBTan style - don't clear existing)
    for (int i = 0; i < bricksPerRow; i++) {
      if (random.nextDouble() < 0.7) { // 70% chance to place a brick
        final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
        final brick = Brick(
          position: Vector2(
            (i * (size.x / bricksPerRow)) + (size.x / bricksPerRow / 2),
            50, // Start at top
          ),
          hitPoints: random.nextInt(level * 2) + 1,
          brickType: _getRandomBrickType(),
          themeColors: currentThemeColors,
        );
        bricks.add(brick);
        add(brick);
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
    
    if (chance < 0.1) {
      return BrickType.explosive;
    } else if (chance < 0.15) {
      return BrickType.time;
    } else if (chance < 0.2) {
      return BrickType.teleport;
    } else {
      return BrickType.normal;
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
          speed: ballSpeed,
          themeColors: currentThemeColors,
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
    
    // Check if all balls have returned to bottom
    _checkBallsReturned();
    
    // Check for game over conditions
    _checkGameOver();
    
    // Update power-ups
    _updatePowerUps(dt);
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
    
    // Generate new row if needed
    if (Random().nextDouble() < 0.8) {
      _generateBricks();
    }
    
    // Increase ball count for next round (BBTan style)
    ballsRemaining++;
    level++;
  }
  
  void _moveBricksDown() {
    for (final brick in bricks) {
      brick.position.y += brickRowHeight;
    }
  }
  
  void _checkGameOver() {
    // Check if any brick has reached the bottom
    for (final brick in bricks) {
      if (brick.position.y > size.y - 200) {
        _gameOver();
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
    
    // Update power-up colors
    for (final powerUp in powerUps) {
      powerUp.themeColors = currentThemeColors;
      powerUp.updateAppearance();
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
    
    // Chance to spawn power-up
    if (Random().nextDouble() < 0.15) {
      _spawnPowerUp(brick.position);
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
    brick.position = Vector2(
      random.nextDouble() * (size.x - brickWidth),
      random.nextDouble() * (size.y / 2),
    );
  }
  
  void _spawnPowerUp(Vector2 position) {
    final powerUpType = _getRandomPowerUpType();
    final currentThemeColors = themeManager.getThemeColors(themeManager.currentTheme);
    final powerUp = PowerUp(
      position: position,
      powerUpType: powerUpType,
      themeColors: currentThemeColors,
    );
    powerUps.add(powerUp);
    add(powerUp);
  }
  
  PowerUpType _getRandomPowerUpType() {
    final random = Random();
    final types = PowerUpType.values;
    return types[random.nextInt(types.length)];
  }
  
  void _updatePowerUps(double dt) {
    powerUps.removeWhere((powerUp) {
      if (powerUp.position.y > size.y) {
        powerUp.removeFromParent();
        return true;
      }
      return false;
    });
  }
  
  void onPowerUpCollected(PowerUp powerUp) {
    powerUps.remove(powerUp);
    
    // Notify mission manager
    missionManager.onPowerUpCollected(powerUp.powerUpType);
    
    // Play power-up collection sound
    audioManager.playSound('power_up');
    
    // Add power-up collection effect
    final powerUpEffect = ParticleEffects.createPowerUpEffect(
      powerUp.position, 
      _getPowerUpColor(powerUp.powerUpType)
    );
    add(powerUpEffect);
    
    switch (powerUp.powerUpType) {
      case PowerUpType.timeFreeze:
        _activateTimeFreeze();
        break;
      case PowerUpType.cloneBall:
        _activateCloneBall();
        break;
      case PowerUpType.laserBall:
        _activateLaserBall();
        break;
    }
  }
  
  void _activateTimeFreeze() {
    gameState.activateTimeFreeze(3.0);
  }
  
  void _activateCloneBall() {
    if (ball == null) return;
    
    // Create a clone of the current ball
    final cloneBall = Ball(
      position: ball!.position.clone(),
      speed: ballSpeed,
    );
    
    // Launch clone in a slightly different direction
    final cloneDirection = ball!.velocity.normalized();
    cloneDirection.rotate(0.3); // 0.3 radians difference
    cloneBall.launch(cloneDirection);
    
    balls.add(cloneBall);
    add(cloneBall);
  }
  
  void _activateLaserBall() {
    if (ball == null) return;
    ball!.activateLaser(5.0); // 5 seconds of laser mode
  }

  Color _getPowerUpColor(PowerUpType powerUpType) {
    switch (powerUpType) {
      case PowerUpType.timeFreeze:
        return Colors.blue;
      case PowerUpType.cloneBall:
        return Colors.green;
      case PowerUpType.laserBall:
        return Colors.red;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw aim line when aiming
    if (isAiming && aimDirection != null) {
      _drawAimLine(canvas);
    }
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
    Vector2 velocity = direction * ballSpeed;
    
    for (int i = 0; i < maxDots; i++) {
      // Draw dot
      canvas.drawCircle(
        Offset(currentPos.x, currentPos.y),
        dotRadius,
        paint,
      );
      
      // Simulate ball physics for next dot position
      currentPos += velocity * (dotSpacing / ballSpeed);
      
      // Check wall bounces
      if (currentPos.x <= 12 || currentPos.x >= size.x - 12) {
        velocity.x = -velocity.x;
        currentPos.x = currentPos.x <= 12 ? 12 : size.x - 12;
      }
      
      if (currentPos.y <= 12) {
        velocity.y = -velocity.y;
        currentPos.y = 12;
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