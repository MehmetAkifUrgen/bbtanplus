import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/crystal_breaker_game.dart';
import '../models/game_state.dart';
import '../services/theme_manager.dart';

class Brick extends RectangleComponent with CollisionCallbacks, HasGameReference<CrystalBreakerGame> {
  int hitPoints;
  int maxHitPoints;
  BrickType brickType;
  ThemeColors? themeColors;
  
  Brick({
    required Vector2 position,
    required this.hitPoints,
    required this.brickType,
    this.themeColors,
  }) : maxHitPoints = hitPoints,
       super(
         position: position,
         size: Vector2(70, 40),
       );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
    updateAppearance();
  }
  
  void updateAppearance() {
    // Update color based on hit points and brick type
    final intensity = hitPoints / maxHitPoints;
    paint.color = Color.lerp(
      Colors.grey.withValues(alpha: 0.5),
      _getBrickTypeColor(),
      intensity,
    )!;
  }
  
  Color _getBrickTypeColor() {
    if (themeColors != null) {
      switch (brickType) {
        case BrickType.normal:
          return themeColors!.normalBrick;
        case BrickType.explosive:
          return themeColors!.explosiveBrick;
        case BrickType.time:
          return themeColors!.timeBrick;
        case BrickType.teleport:
          return themeColors!.teleportBrick;
      }
    }
    
    // Fallback colors
    switch (brickType) {
      case BrickType.normal:
        return Colors.blue;
      case BrickType.explosive:
        return Colors.red;
      case BrickType.time:
        return Colors.purple;
      case BrickType.teleport:
        return Colors.green;
    }
  }
  
  void hit() {
    hitPoints--;
    updateAppearance();
    
    if (hitPoints <= 0) {
      destroy();
    } else {
      // Handle special brick effects on hit
      _handleSpecialEffect();
    }
  }
  
  void _handleSpecialEffect() {
    switch (brickType) {
      case BrickType.explosive:
        // Explosive bricks damage nearby bricks when hit
        _explodeNearbyBricks();
        break;
      case BrickType.time:
        // Time bricks slow down time when hit
        game.gameState.activateTimeEffect('timeSlow', 3.0);
        break;
      case BrickType.teleport:
        // Teleport bricks move to a random position when hit
        _teleportToRandomPosition();
        break;
      case BrickType.normal:
        // Normal bricks have no special effect
        break;
    }
  }
  
  void _explodeNearbyBricks() {
    final explosionRadius = 100.0;
    final nearbyBricks = game.children.whereType<Brick>().where((brick) {
      if (brick == this) return false;
      final distance = (brick.position - position).length;
      return distance <= explosionRadius;
    });
    
    for (final brick in nearbyBricks) {
      brick.hit(); // Chain reaction possible
    }
  }
  
  void _teleportToRandomPosition() {
    final random = Random();
    final gameSize = game.size;
    final newX = random.nextDouble() * (gameSize.x - size.x);
    final newY = random.nextDouble() * (gameSize.y * 0.6); // Keep in upper 60% of screen
    position = Vector2(newX, newY);
  }
  
  void destroy() {
    game.onBrickDestroyed(this);
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    // Draw modern brick with gradient and rounded corners
    _drawModernBrick(canvas);
    
    // Add special visual effects for each brick type
    _renderSpecialEffects(canvas);
    
    // Draw hit points text with shadow
    _drawHitPointsText(canvas);
    
    // Draw special effect indicators
    if (brickType != BrickType.normal) {
      _drawSpecialIndicator(canvas);
    }
  }
  
  void _drawModernBrick(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    
    // Create gradient based on brick type and hit points
    final baseColor = _getBrickTypeColor();
    final intensity = hitPoints / maxHitPoints;
    
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.9 * intensity),
        baseColor.withValues(alpha: 0.6 * intensity),
        baseColor.withValues(alpha: 0.8 * intensity),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);
    
    // Draw main brick with gradient
    canvas.drawRRect(roundedRect, gradientPaint);
    
    // Add subtle border for depth
    final borderPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawRRect(roundedRect, borderPaint);
    
    // Add highlight for 3D effect
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.x - 4, size.y / 3),
      const Radius.circular(6),
    );
    
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    
    canvas.drawRRect(highlightRect, highlightPaint);
  }
  
  void _drawHitPointsText(Canvas canvas) {
    // Draw text shadow first
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: hitPoints.toString(),
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.5),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    shadowPainter.layout();
    
    final shadowOffset = Offset(
      (size.x - shadowPainter.width) / 2 + 1,
      (size.y - shadowPainter.height) / 2 + 1,
    );
    
    shadowPainter.paint(canvas, shadowOffset);
    
    // Draw main text
    final textPainter = TextPainter(
      text: TextSpan(
        text: hitPoints.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textOffset = Offset(
      (size.x - textPainter.width) / 2,
      (size.y - textPainter.height) / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  void _renderSpecialEffects(Canvas canvas) {
    switch (brickType) {
      case BrickType.explosive:
        // Add pulsing glow effect
        final glowPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawRect(Offset.zero & size.toSize(), glowPaint);
        break;
      case BrickType.time:
        // Add shimmering effect
        final shimmerPaint = Paint()
          ..color = Colors.purple.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawRect(Offset.zero & size.toSize(), shimmerPaint);
        break;
      case BrickType.teleport:
        // Add sparkling border
        final borderPaint = Paint()
          ..color = Colors.green.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(Offset.zero & size.toSize(), borderPaint);
        break;
      case BrickType.normal:
        // No special effects
        break;
    }
  }
  
  void _drawSpecialIndicator(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    switch (brickType) {
      case BrickType.explosive:
        paint.color = Colors.orange;
        // Draw explosion symbol
        canvas.drawCircle(
          Offset(size.x - 10, 10),
          5,
          paint,
        );
        break;
      case BrickType.time:
        paint.color = Colors.yellow;
        // Draw clock symbol
        canvas.drawCircle(
          Offset(size.x - 10, 10),
          5,
          paint,
        );
        canvas.drawLine(
          Offset(size.x - 10, 10),
          Offset(size.x - 10, 5),
          paint,
        );
        break;
      case BrickType.teleport:
        paint.color = Colors.cyan;
        // Draw teleport symbol
        canvas.drawRect(
          Rect.fromLTWH(size.x - 15, 5, 10, 10),
          paint,
        );
        break;
      case BrickType.normal:
        break;
    }
  }
}