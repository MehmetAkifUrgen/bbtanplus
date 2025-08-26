import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/crystal_breaker_game.dart';
import '../services/theme_manager.dart';
import 'brick.dart';


class Ball extends CircleComponent with CollisionCallbacks, HasGameReference<CrystalBreakerGame> {
  Vector2 velocity = Vector2.zero();
  double speed;
  bool isLaserMode = false;
  double laserModeRemaining = 0.0;
  ThemeColors? themeColors;
  Color originalColor;
  Vector2? aimDirection; // Store aim direction for barrel rotation
  
  Ball({
    required Vector2 position,
    required this.speed,
    this.themeColors,
    this.aimDirection,
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
    
    // Bounce off top wall (at Y=100 where the border is)
    if (position.y <= 100 + radius) {
      position.y = 100 + radius;
      velocity.y = velocity.y.abs();
    }
    
    // No bottom wall bounce - BBTan style (balls fall off screen)
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
    // Draw tank barrel when ball is stationary
    if (velocity.length < 10) {
      _drawTankBarrel(canvas);
    }
    
    // Draw light blue magical orb instead of grenade
    _drawMagicalOrb(canvas);
    
    // Add explosion effect for laser mode
    if (isLaserMode) {
      _drawExplosionEffect(canvas);
    }
  }
  
  // Method to update aim direction from game
  void updateAimDirection(Vector2? direction) {
    aimDirection = direction;
  }
  
  void _drawMagicalOrb(Canvas canvas) {
    // Draw light blue magical orb with glowing effect
    final orbGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.2,
      colors: [
        const Color(0xFFFFFFFF), // White center
        const Color(0xFF87CEEB), // Sky blue
        const Color(0xFF4682B4), // Steel blue
        const Color(0xFF1E90FF), // Dodger blue
        const Color(0xFF0066CC), // Dark blue
      ],
      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
    );
    
    final orbPaint = Paint()
      ..shader = orbGradient.createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: radius,
      ));
    
    // Draw main orb
    canvas.drawCircle(Offset.zero, radius, orbPaint);
    
    // Add magical sparkles
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    // Draw sparkles around the orb
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * pi) / 8;
      final sparkleDistance = radius * 1.3;
      final sparkleX = cos(angle) * sparkleDistance;
      final sparkleY = sin(angle) * sparkleDistance;
      
      _drawSparkle(canvas, sparkleX, sparkleY, sparklePaint);
    }
    
    // Add inner glow
    final glowPaint = Paint()
      ..color = const Color(0xFF87CEEB).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(Offset.zero, radius * 0.7, glowPaint);
    
    // Add magical energy swirls
    final swirlPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw energy swirls
    for (int i = 0; i < 3; i++) {
      final swirlPath = Path();
      final startAngle = (i * 2 * pi) / 3;
      
      for (int j = 0; j <= 20; j++) {
        final t = j / 20.0;
        final angle = startAngle + t * 2 * pi;
        final r = radius * 0.3 + (radius * 0.4 * t);
        final x = cos(angle) * r;
        final y = sin(angle) * r;
        
        if (j == 0) {
          swirlPath.moveTo(x, y);
        } else {
          swirlPath.lineTo(x, y);
        }
      }
      
      canvas.drawPath(swirlPath, swirlPaint);
    }
  }
  
  void _drawSparkle(Canvas canvas, double x, double y, Paint paint) {
    // Draw a small star-like sparkle
    final sparkleSize = 2.0;
    
    // Horizontal line
    canvas.drawLine(
      Offset(x - sparkleSize, y),
      Offset(x + sparkleSize, y),
      paint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(x, y - sparkleSize),
      Offset(x, y + sparkleSize),
      paint,
    );
    
    // Diagonal lines
    canvas.drawLine(
      Offset(x - sparkleSize * 0.7, y - sparkleSize * 0.7),
      Offset(x + sparkleSize * 0.7, y + sparkleSize * 0.7),
      paint,
    );
    
    canvas.drawLine(
      Offset(x + sparkleSize * 0.7, y - sparkleSize * 0.7),
      Offset(x - sparkleSize * 0.7, y + sparkleSize * 0.7),
      paint,
    );
  }
  
  void _drawHandGrenade(Canvas canvas) {
    // Hand grenade body (oval shape)
    final grenadeGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 1.0,
      colors: [
        const Color(0xFF4A5D23), // Olive green highlight
        const Color(0xFF2F3E15), // Dark olive green
        const Color(0xFF1C2409), // Very dark green
        const Color(0xFF0F1204), // Almost black green
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    
    final grenadePaint = Paint()
      ..shader = grenadeGradient.createShader(Rect.fromLTWH(
        -radius,
        -radius * 1.2,
        radius * 2,
        radius * 2.4,
      ));
    
    // Draw oval grenade body
    canvas.drawOval(
      Rect.fromLTWH(
        -radius * 0.8,
        -radius * 1.1,
        radius * 1.6,
        radius * 2.2,
      ),
      grenadePaint,
    );
    
    // Grenade segments/ridges
    final segmentPaint = Paint()
      ..color = const Color(0xFF1C2409)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Horizontal ridges
    for (int i = 0; i < 5; i++) {
      final y = -radius * 0.8 + i * (radius * 0.4);
      canvas.drawLine(
        Offset(-radius * 0.7, y),
        Offset(radius * 0.7, y),
        segmentPaint,
      );
    }
    
    // Vertical ridges
    for (int i = 0; i < 4; i++) {
      final x = -radius * 0.6 + i * (radius * 0.4);
      canvas.drawLine(
        Offset(x, -radius * 0.8),
        Offset(x, radius * 0.8),
        segmentPaint,
      );
    }
    
    // Safety lever (spoon)
    final leverPaint = Paint()
      ..color = const Color(0xFF8C8C8C) // Metallic gray
      ..style = PaintingStyle.fill;
    
    final leverPath = Path();
    leverPath.moveTo(-radius * 0.3, -radius * 1.1);
    leverPath.lineTo(-radius * 0.8, -radius * 1.4);
    leverPath.lineTo(-radius * 0.6, -radius * 1.6);
    leverPath.lineTo(-radius * 0.1, -radius * 1.3);
    leverPath.close();
    
    canvas.drawPath(leverPath, leverPaint);
    
    // Safety pin removed for cleaner look
    
    // Fuse/striker mechanism at top
    final strikePaint = Paint()
      ..color = const Color(0xFF4A4A4A) // Dark gray
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(
        -radius * 0.2,
        -radius * 1.3,
        radius * 0.4,
        radius * 0.3,
      ),
      strikePaint,
    );
    
    // Metallic highlight on body
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawOval(
      Rect.fromLTWH(
        -radius * 0.4,
        -radius * 0.8,
        radius * 0.6,
        radius * 0.8,
      ),
      highlightPaint,
    );
    
    // Military markings
    final markingPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw "M67" marking
    canvas.drawLine(
      Offset(-radius * 0.3, radius * 0.2),
      Offset(-radius * 0.1, radius * 0.2),
      markingPaint,
    );
    
    canvas.drawLine(
      Offset(-radius * 0.3, radius * 0.2),
      Offset(-radius * 0.3, radius * 0.5),
      markingPaint,
    );
    
    canvas.drawLine(
      Offset(-radius * 0.2, radius * 0.35),
      Offset(-radius * 0.1, radius * 0.5),
      markingPaint,
    );
    
    // Add subtle shadow at bottom
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawOval(
      Rect.fromLTWH(-radius * 0.8, radius * 0.7, radius * 1.6, radius * 0.3),
      shadowPaint,
    );
  }
  
  void _drawRealisticFuse(Canvas canvas) {
    // Fuse rope with twisted texture
    final fuseBasePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Main fuse line with slight curve
    final fusePath = Path();
    fusePath.moveTo(0, -radius);
    fusePath.quadraticBezierTo(-3, -radius - 8, -6, -radius - 16);
    canvas.drawPath(fusePath, fuseBasePaint);
    
    // Fuse texture lines
    final textureLinePaint = Paint()
      ..color = const Color(0xFF654321)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 4; i++) {
      final t = i / 3.0;
      final x = -3 * t;
      final y = -radius - 8 * t;
      canvas.drawLine(
        Offset(x - 1, y),
        Offset(x + 1, y),
        textureLinePaint,
      );
    }
    
    // Burning fuse tip with realistic fire
    _drawFuseFire(canvas);
  }
  
  void _drawFuseFire(Canvas canvas) {
    final fuseEndX = -6.0;
    final fuseEndY = -radius - 16.0;
    
    // Fire core (white-hot center)
    final fireCorePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    
    canvas.drawCircle(Offset(fuseEndX, fuseEndY), 1.5, fireCorePaint);
    
    // Fire middle layer (yellow-orange)
    final fireMiddlePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawCircle(Offset(fuseEndX, fuseEndY), 2.5, fireMiddlePaint);
    
    // Fire outer layer (orange-red)
    final fireOuterPaint = Paint()
      ..color = const Color(0xFFFF4500)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(Offset(fuseEndX, fuseEndY), 3.5, fireOuterPaint);
    
    // Animated spark particles
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.8);
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * 3.14159) / 6;
      final distance = 4 + (i % 2) * 2;
      final x = fuseEndX + distance * cos(angle);
      final y = fuseEndY + distance * sin(angle);
      canvas.drawCircle(Offset(x, y), 0.8, sparkPaint);
    }
  }
  
  void _drawWarningSymbol(Canvas canvas) {
    // Warning triangle with glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final warningPath = Path();
    warningPath.moveTo(0, -6);
    warningPath.lineTo(-5, 4);
    warningPath.lineTo(5, 4);
    warningPath.close();
    
    canvas.drawPath(warningPath, glowPaint);
    
    // Main warning triangle
    final warningPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      ).createShader(Rect.fromLTWH(-5, -6, 10, 10));
    
    canvas.drawPath(warningPath, warningPaint);
    
    // Triangle border
    final borderPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(warningPath, borderPaint);
    
    // Exclamation mark with 3D effect
    final exclamationShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    
    // Shadow
    canvas.drawRect(Rect.fromLTWH(-0.5, -2.5, 1.2, 4.2), exclamationShadowPaint);
    canvas.drawCircle(Offset(0.2, 2.2), 0.6, exclamationShadowPaint);
    
    // Main exclamation
    final exclamationPaint = Paint()
      ..color = const Color(0xFF2C3E50);
    
    canvas.drawRect(Rect.fromLTWH(-0.6, -2.8, 1.2, 4.2), exclamationPaint);
    canvas.drawCircle(Offset.zero, 0.6, exclamationPaint);
  }
  
  void _drawExplosionEffect(Canvas canvas) {
    // Multiple explosion rings
    final explosionColors = [Colors.white, Colors.yellow, Colors.orange, Colors.red];
    
    for (int i = 0; i < 4; i++) {
      final explosionPaint = Paint()
        ..color = explosionColors[i].withValues(alpha: 0.3 - i * 0.05)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + i * 3.0);
      
      canvas.drawCircle(
        Offset.zero,
        radius + 5 + i * 4,
        explosionPaint,
      );
    }
    
    // Explosion rays
    final rayPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * 3.14159) / 8;
      final startX = (radius + 8) * cos(angle);
      final startY = (radius + 8) * sin(angle);
      final endX = (radius + 15) * cos(angle);
      final endY = (radius + 15) * sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }
  

  

  

  

  

  

  
  void _drawTankBarrel(Canvas canvas) {
    if (aimDirection == null) return;
    
    // Calculate barrel rotation angle from aim direction
    final angle = atan2(aimDirection!.y, aimDirection!.x);
    
    canvas.save();
    
    // Translate to ball center and rotate barrel
    canvas.translate(0, 0);
    canvas.rotate(angle);
    
    // Draw tank barrel
    final barrelPaint = Paint()
      ..color = const Color(0xFF2F4F4F)
      ..style = PaintingStyle.fill;
    
    // Main barrel tube
    canvas.drawRect(
      Rect.fromLTWH(0, -3, 25, 6),
      barrelPaint,
    );
    
    // Barrel tip
    final tipPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(23, -2, 4, 4),
      tipPaint,
    );
    
    // Barrel highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(2, -2, 20, 2),
      highlightPaint,
    );
    
    canvas.restore();
  }
}