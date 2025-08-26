import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/crystal_breaker_game.dart';
import '../services/theme_manager.dart';
import 'brick.dart';
import 'power_up.dart';

class Ball extends CircleComponent with CollisionCallbacks, HasGameReference<CrystalBreakerGame> {
  Vector2 velocity = Vector2.zero();
  double speed;
  bool isLaserMode = false;
  double laserModeRemaining = 0.0;
  ThemeColors? themeColors;
  Color originalColor;
  
  Ball({
    required Vector2 position,
    required this.speed,
    this.themeColors,
  }) : originalColor = themeColors?.ballColor ?? Colors.cyan,
       super(
          position: position,
          radius: 12,
          paint: Paint()..color = themeColors?.ballColor ?? Colors.cyan,
        );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update laser mode
    if (isLaserMode) {
      laserModeRemaining -= dt;
      if (laserModeRemaining <= 0) {
        isLaserMode = false;
        laserModeRemaining = 0.0;
        paint.color = originalColor;
      }
    }
    
    // Apply time effects
    final timeMultiplier = game.gameState.getTimeMultiplier();
    final adjustedVelocity = velocity * timeMultiplier;
    
    // Move the ball
    position += adjustedVelocity * dt;
    
    // Keep ball within horizontal bounds
    if (position.x <= radius) {
      position.x = radius;
      velocity.x = velocity.x.abs();
    } else if (position.x >= game.size.x - radius) {
      position.x = game.size.x - radius;
      velocity.x = -velocity.x.abs();
    }
    
    // Bounce off top wall
    if (position.y <= radius) {
      position.y = radius;
      velocity.y = velocity.y.abs();
    }
  }
  
  void launch(Vector2 direction) {
    velocity = direction.normalized() * speed;
  }
  
  void stop() {
    velocity = Vector2.zero();
  }
  
  void activateLaser(double duration) {
    isLaserMode = true;
    laserModeRemaining = duration;
    paint.color = Colors.red;
  }
  
  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
      return true;
    } else if (other is PowerUp) {
      _handlePowerUpCollision(other);
      return true;
    } else if (other is RectangleComponent) {
      // Wall collision
      _handleWallCollision(intersectionPoints);
      return true;
    }
    return false;
  }
  
  void _handleBrickCollision(Brick brick, Set<Vector2> intersectionPoints) {
    if (isLaserMode) {
      // Laser mode destroys brick instantly
      brick.destroy();
    } else {
      // Normal collision - reduce brick hit points
      brick.hit();
      
      // Calculate bounce direction
      if (intersectionPoints.isNotEmpty) {
        final brickCenter = brick.position + brick.size / 2;
        final ballCenter = position;
        
        final collisionNormal = (ballCenter - brickCenter).normalized();
        
        // Reflect velocity
        velocity = velocity - (collisionNormal * (2 * velocity.dot(collisionNormal)));
      }
    }
  }
  
  void _handlePowerUpCollision(PowerUp powerUp) {
    game.onPowerUpCollected(powerUp);
    powerUp.removeFromParent();
  }
  
  void _handleWallCollision(Set<Vector2> intersectionPoints) {
    if (intersectionPoints.isNotEmpty) {
      final collisionPoint = intersectionPoints.first;
      
      // Play bounce sound
      game.audioManager.playSound('ball_bounce');
      
      // Determine which wall was hit based on collision point
      if (collisionPoint.x <= 0 || collisionPoint.x >= game.size.x) {
        // Left or right wall
        velocity.x = -velocity.x;
      } else if (collisionPoint.y <= 0) {
        // Top wall
        velocity.y = -velocity.y;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Draw football base (white)
    final footballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, radius, footballPaint);
    
    // Draw football pattern (black pentagons and lines)
    final blackPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw pentagon pattern
    final path = Path();
    final centerOffset = Offset.zero;
    final pentagonRadius = radius * 0.4;
    
    // Draw central pentagon
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final x = centerOffset.dx + pentagonRadius * cos(angle);
      final y = centerOffset.dy + pentagonRadius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    // Fill pentagon
    final pentagonFillPaint = Paint()..color = Colors.black;
    canvas.drawPath(path, pentagonFillPaint);
    
    // Draw connecting lines
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final startX = centerOffset.dx + pentagonRadius * cos(angle);
      final startY = centerOffset.dy + pentagonRadius * sin(angle);
      final endX = centerOffset.dx + radius * 0.9 * cos(angle);
      final endY = centerOffset.dy + radius * 0.9 * sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        blackPaint,
      );
    }
    
    // Add glow effect for laser mode
    if (isLaserMode) {
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawCircle(
        Offset.zero,
        radius + 5,
        glowPaint,
      );
    }
  }
}