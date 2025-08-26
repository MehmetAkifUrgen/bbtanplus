import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/crystal_breaker_game.dart';
import '../models/game_state.dart';
import '../services/theme_manager.dart';

class PowerUp extends CircleComponent with HasGameReference<CrystalBreakerGame> {
  PowerUpType powerUpType;
  double fallSpeed = 100.0;
  double rotationSpeed = 2.0;
  double currentRotation = 0.0;
  ThemeColors? themeColors;
  
  PowerUp({
    required Vector2 position,
    required this.powerUpType,
    this.themeColors,
  }) : super(
         position: position,
         radius: 15,
       );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
    updateAppearance();
  }
  
  void updateAppearance() {
    Color color;
    
    switch (powerUpType) {
      case PowerUpType.timeFreeze:
        color = themeColors?.powerUpColor ?? Colors.lightBlue;
        break;
      case PowerUpType.cloneBall:
        color = themeColors?.powerUpColor ?? Colors.orange;
        break;
      case PowerUpType.laserBall:
        color = themeColors?.powerUpColor ?? Colors.red;
        break;
    }
    
    paint.color = color;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply time effects
    final timeMultiplier = game.gameState.getTimeMultiplier();
    
    // Fall down
    position.y += fallSpeed * timeMultiplier * dt;
    
    // Rotate for visual effect
    currentRotation += rotationSpeed * dt;
    angle = currentRotation;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw power-up icon
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    switch (powerUpType) {
      case PowerUpType.timeFreeze:
        _drawTimeFreezeIcon(canvas, paint);
        break;
      case PowerUpType.cloneBall:
        _drawCloneBallIcon(canvas, paint);
        break;
      case PowerUpType.laserBall:
        _drawLaserBallIcon(canvas, paint);
        break;
    }
  }
  
  void _drawTimeFreezeIcon(Canvas canvas, Paint paint) {
    // Draw snowflake-like pattern
    // final center = Offset.zero; // Unused variable removed
    final lines = [
      [Offset(-8, 0), Offset(8, 0)],
      [Offset(0, -8), Offset(0, 8)],
      [Offset(-6, -6), Offset(6, 6)],
      [Offset(-6, 6), Offset(6, -6)],
    ];
    
    for (final line in lines) {
      canvas.drawLine(line[0], line[1], paint);
    }
  }
  
  void _drawCloneBallIcon(Canvas canvas, Paint paint) {
    // Draw two overlapping circles
    canvas.drawCircle(Offset(-3, 0), 5, paint);
    canvas.drawCircle(Offset(3, 0), 5, paint);
  }
  
  void _drawLaserBallIcon(Canvas canvas, Paint paint) {
    // Draw lightning bolt pattern
    final path = Path()
      ..moveTo(-5, -8)
      ..lineTo(2, -2)
      ..lineTo(-2, -2)
      ..lineTo(5, 8)
      ..lineTo(-2, 2)
      ..lineTo(2, 2)
      ..close();
    
    canvas.drawPath(path, paint);
  }
}