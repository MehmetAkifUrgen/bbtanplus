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
  
  // Dragon movement variables
  bool isDragon = false;
  double movementSpeed = 50.0;
  double movementDirection = 1.0; // 1 for right, -1 for left
  double originalX = 0.0;
  double movementRange = 100.0;
  
  // Character sprites cache
  static final Map<String, Sprite> _spriteCache = {};
  Sprite? characterSprite;
  
  Brick({
    required Vector2 position,
    required this.hitPoints,
    required this.brickType,
    this.themeColors,
    Vector2? customSize,
  }) : maxHitPoints = hitPoints,
       super(
         position: position,
         size: customSize ?? Vector2(50, 50), // Use custom size or default
       ) {
    // Check if this is a dragon brick (lowered threshold)
    isDragon = hitPoints >= 20;
    originalX = position.x;
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Create hitbox that matches the brick size exactly
    add(RectangleHitbox(size: size));
    updateAppearance();
    await _loadCharacterSprite();
  }
  
  Future<void> _loadCharacterSprite() async {
    try {
      String imagePath;
      
      // Can puanına göre karakter seçimi (daha agresif sistem)
      if (hitPoints <= 3) {
        imagePath = 'dworf-removebg-preview.png'; // Cüce (1-3 can)
      } else if (hitPoints <= 7) {
        imagePath = 'knight-removebg-preview.png'; // Şövalye (4-7 can)
      } else if (hitPoints <= 12) {
        imagePath = 'ork-removebg-preview.png'; // Ork (8-12 can)
      } else if (hitPoints <= 19) {
        imagePath = 'elephant-removebg-preview.png'; // Fil (13-19 can)
      } else {
        imagePath = 'dragon-removebg-preview.png'; // Ejderha (20+ can)
      }
      
      // Check if sprite is already cached
      if (!_spriteCache.containsKey(imagePath)) {
        _spriteCache[imagePath] = await Sprite.load(imagePath);
      }
      
      characterSprite = _spriteCache[imagePath];
    } catch (e) {
      // If loading fails, characterSprite will remain null and fallback drawing will be used
      print('Failed to load character sprite: $e');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Dragon movement logic
    if (isDragon && game.isMounted) {
      _updateDragonMovement(dt);
    }
  }
  
  void _updateDragonMovement(double dt) {
    // Move dragon horizontally
    final movement = movementSpeed * movementDirection * dt;
    position.x += movement;
    
    // Check boundaries and reverse direction if needed
    final leftBound = originalX - movementRange;
    final rightBound = originalX + movementRange;
    
    // Also check game boundaries
    final gameLeftBound = 35.0; // Account for brick width
    final gameRightBound = game.size.x - 35.0;
    
    if (position.x <= leftBound || position.x <= gameLeftBound) {
      position.x = leftBound.clamp(gameLeftBound, gameRightBound);
      movementDirection = 1.0; // Move right
    } else if (position.x >= rightBound || position.x >= gameRightBound) {
      position.x = rightBound.clamp(gameLeftBound, gameRightBound);
      movementDirection = -1.0; // Move left
    }
  }
  
  void updateAppearance() {
    // Remove background color - characters will be drawn without brick background
    paint.color = Colors.transparent;
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
    final brickMargin = 10.0;
    
    // Ensure teleported brick stays within safe boundaries
    final safeX = brickMargin + random.nextDouble() * (gameSize.x - 2 * brickMargin - size.x);
    final safeY = 120 + random.nextDouble() * (gameSize.y * 0.4 - 120); // Stay below UI and in upper area
    
    position = Vector2(safeX, safeY);
  }
  
  void destroy() {
    game.onBrickDestroyed(this);
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    // Draw character based on hit points instead of modern brick
    _drawCharacterByHitPoints(canvas);
    
    // Add special visual effects for each brick type
    _renderSpecialEffects(canvas);
    
    // Draw hit points text with shadow
    _drawHitPointsText(canvas);
    
    // Draw special effect indicators
    if (brickType != BrickType.normal) {
      _drawSpecialIndicator(canvas);
    }
  }
  
  // Character frame removed - no background borders

  void _drawCharacterByHitPoints(Canvas canvas) {
    // Use loaded sprite if available, otherwise fallback to original drawing
    if (characterSprite != null) {
      _drawCharacterImage(canvas);
    } else {
      // Fallback to original character drawing
      if (hitPoints <= 5) {
        _drawDwarf(canvas);
      } else if (hitPoints <= 10) {
        _drawHuman(canvas);
      } else if (hitPoints <= 15) {
        _drawHuman(canvas); // Use human as fallback for gandalf
      } else if (hitPoints <= 20) {
        _drawOrc(canvas);
      } else if (hitPoints <= 30) {
        _drawElephant(canvas);
      } else {
        _drawDragon(canvas);
      }
    }
  }
  
  void _drawCharacterImage(Canvas canvas) {
    if (characterSprite == null) return;
    
    // Calculate position to center the image in the brick
    final imageSize = Vector2(size.x * 0.9, size.y * 0.9); // Make image 90% of brick size
    final imagePosition = Vector2(
      (size.x - imageSize.x) / 2,
      (size.y - imageSize.y) / 2,
    );
    
    // Draw the sprite
    characterSprite!.render(
      canvas,
      position: imagePosition,
      size: imageSize,
    );
  }
  
  void _drawDwarf(Canvas canvas) {
    // Draw dwarf character (0-5 hit points) - scaled to fill brick area
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    final scale = 1.4; // Scale factor to make character fill the brick area
    
    // Dwarf head (larger proportionally)
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(centerX, centerY - 5 * scale), 10 * scale, headPaint);
    
    // Large beard (main dwarf feature)
    final beardPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 12 * scale, centerY - 2 * scale, 24 * scale, 18 * scale),
      beardPaint,
    );
    
    // Helmet with horns
    final helmetPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 10 * scale, centerY - 15 * scale, 20 * scale, 12 * scale),
      helmetPaint,
    );
    
    // Helmet horns
    final hornPaint = Paint()
      ..color = const Color(0xFFFFFFE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(centerX - 8 * scale, centerY - 15 * scale),
      Offset(centerX - 12 * scale, centerY - 22 * scale),
      hornPaint,
    );
    canvas.drawLine(
      Offset(centerX + 8 * scale, centerY - 15 * scale),
      Offset(centerX + 12 * scale, centerY - 22 * scale),
      hornPaint,
    );
    
    // Stocky body
    final bodyPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 8 * scale, centerY + 8 * scale, 16 * scale, 20 * scale),
      bodyPaint,
    );
    
    // Large axe
    final axePaint = Paint()..color = const Color(0xFF654321);
    canvas.drawRect(
      Rect.fromLTWH(centerX + 10 * scale, centerY - 5 * scale, 3 * scale, 25 * scale),
      axePaint,
    );
    
    final axeHeadPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawOval(
      Rect.fromLTWH(centerX + 8 * scale, centerY - 8 * scale, 8 * scale, 12 * scale),
      axeHeadPaint,
    );
    
    // Eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 3 * scale, centerY - 8 * scale), 1.5 * scale, eyePaint);
    canvas.drawCircle(Offset(centerX + 3 * scale, centerY - 8 * scale), 1.5 * scale, eyePaint);
  }
  
  void _drawHuman(Canvas canvas) {
    // Draw human character (5-10 hit points) - scaled to fill brick area
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    final scale = 1.4; // Scale factor to make character fill the brick area
    
    // Human head
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(centerX, centerY - 8 * scale), 8 * scale, headPaint);
    
    // Hair
    final hairPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 8 * scale, centerY - 16 * scale, 16 * scale, 10 * scale),
      hairPaint,
    );
    
    // Body
    final bodyPaint = Paint()..color = const Color(0xFF4169E1);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 8 * scale, centerY + 2 * scale, 16 * scale, 22 * scale),
      bodyPaint,
    );
    
    // Arms
    final armPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12 * scale, centerY + 5 * scale, 4 * scale, 15 * scale),
      armPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX + 8 * scale, centerY + 5 * scale, 4 * scale, 15 * scale),
      armPaint,
    );
    
    // Sword
    final swordPaint = Paint()
      ..color = const Color(0xFF696969)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(centerX + 15 * scale, centerY + 8 * scale),
      Offset(centerX + 22 * scale, centerY - 5 * scale),
      swordPaint,
    );
    
    // Sword hilt
    final hiltPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRect(
      Rect.fromLTWH(centerX + 13 * scale, centerY + 6 * scale, 4 * scale, 4 * scale),
      hiltPaint,
    );
    
    // Eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 2 * scale, centerY - 10 * scale), 1 * scale, eyePaint);
    canvas.drawCircle(Offset(centerX + 2 * scale, centerY - 10 * scale), 1 * scale, eyePaint);
    
    // Mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(centerX - 2 * scale, centerY - 5 * scale),
      Offset(centerX + 2 * scale, centerY - 5 * scale),
      mouthPaint,
    );
  }
  
  void _drawOrc(Canvas canvas) {
    // Draw orc character (10-20 hit points) - scaled to fill brick area
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    final scale = 1.4; // Scale factor to make character fill the brick area
    
    // Orc head (greenish)
    final headPaint = Paint()..color = const Color(0xFF9ACD32);
    canvas.drawCircle(Offset(centerX, centerY - 8 * scale), 10 * scale, headPaint);
    
    // Tusks (main orc feature)
    final tuskPaint = Paint()..color = const Color(0xFFFFFFE0);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 8 * scale, centerY - 2 * scale, 4 * scale, 8 * scale),
      tuskPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(centerX + 4 * scale, centerY - 2 * scale, 4 * scale, 8 * scale),
      tuskPaint,
    );
    
    // Large pointed ears
    final earPaint = Paint()..color = const Color(0xFF9ACD32);
    final leftEar = Path();
    leftEar.moveTo(centerX - 10 * scale, centerY - 8 * scale);
    leftEar.lineTo(centerX - 15 * scale, centerY - 15 * scale);
    leftEar.lineTo(centerX - 8 * scale, centerY - 12 * scale);
    leftEar.close();
    canvas.drawPath(leftEar, earPaint);
    
    final rightEar = Path();
    rightEar.moveTo(centerX + 10 * scale, centerY - 8 * scale);
    rightEar.lineTo(centerX + 15 * scale, centerY - 15 * scale);
    rightEar.lineTo(centerX + 8 * scale, centerY - 12 * scale);
    rightEar.close();
    canvas.drawPath(rightEar, earPaint);
    
    // Muscular body
    final bodyPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 10 * scale, centerY + 2 * scale, 20 * scale, 22 * scale),
      bodyPaint,
    );
    
    // Large club
    final clubPaint = Paint()..color = const Color(0xFF654321);
    canvas.drawRect(
      Rect.fromLTWH(centerX + 12 * scale, centerY - 2 * scale, 4 * scale, 20 * scale),
      clubPaint,
    );
    
    // Club head
    final clubHeadPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawOval(
      Rect.fromLTWH(centerX + 10 * scale, centerY - 8 * scale, 8 * scale, 8 * scale),
      clubHeadPaint,
    );
    
    // Angry red eyes
    final eyePaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(centerX - 3 * scale, centerY - 10 * scale), 2 * scale, eyePaint);
    canvas.drawCircle(Offset(centerX + 3 * scale, centerY - 10 * scale), 2 * scale, eyePaint);
    
    // Angry mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(centerX - 4 * scale, centerY - 4 * scale),
      Offset(centerX + 4 * scale, centerY - 4 * scale),
      mouthPaint,
    );
  }
  
  void _drawElephant(Canvas canvas) {
    // Draw elephant character (20-30 hit points) - scaled to fill brick area
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    final scale = 1.4; // Scale factor to make character fill the brick area
    
    // Large elephant head
    final headPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 12 * scale, centerY - 12 * scale, 24 * scale, 20 * scale),
      headPaint,
    );
    
    // Trunk (main elephant feature)
    final trunkPaint = Paint()
      ..color = const Color(0xFF696969)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    
    final trunkPath = Path();
    trunkPath.moveTo(centerX, centerY + 2 * scale);
    trunkPath.quadraticBezierTo(
      centerX - 8 * scale, centerY + 10 * scale,
      centerX - 5 * scale, centerY + 18 * scale,
    );
    canvas.drawPath(trunkPath, trunkPaint);
    
    // Large ears
    final earPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 20 * scale, centerY - 8 * scale, 12 * scale, 16 * scale),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(centerX + 8 * scale, centerY - 8 * scale, 12 * scale, 16 * scale),
      earPaint,
    );
    
    // Tusks
    final tuskPaint = Paint()..color = const Color(0xFFFFFFE0);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 8 * scale, centerY + 5 * scale, 3 * scale, 12 * scale),
      tuskPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(centerX + 5 * scale, centerY + 5 * scale, 3 * scale, 12 * scale),
      tuskPaint,
    );
    
    // Body
    final bodyPaint = Paint()..color = const Color(0xFF696969);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 10 * scale, centerY + 8 * scale, 20 * scale, 16 * scale),
      bodyPaint,
    );
    
    // Small eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 4 * scale, centerY - 5 * scale), 2 * scale, eyePaint);
    canvas.drawCircle(Offset(centerX + 4 * scale, centerY - 5 * scale), 2 * scale, eyePaint);
  }
  
  void _drawKnight(Canvas canvas) {
    // Draw simple knight (10-20 hit points)
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    
    // Background with royal gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF4169E1).withValues(alpha: 0.9),
        const Color(0xFF191970).withValues(alpha: 0.8),
      ],
    );
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    
    // Large knight head
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(centerX, centerY - 8), 12, headPaint);
    
    // Large metallic helmet (main feature)
    final helmetPaint = Paint()..color = const Color(0xFF708090);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 14, centerY - 18, 28, 16),
      helmetPaint,
    );
    
    // Helmet visor (distinctive feature)
    final visorPaint = Paint()..color = const Color(0xFF0F0F0F);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 10, centerY - 8, 20, 6),
      visorPaint,
    );
    
    // Large red plume (very visible)
    final plumePaint = Paint()
      ..color = const Color(0xFFDC143C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    
    canvas.drawLine(
      Offset(centerX, centerY - 18),
      Offset(centerX, centerY - 30),
      plumePaint,
    );
    
    // Armored body
    final armorPaint = Paint()..color = const Color(0xFFC0C0C0);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, centerY + 2, 24, 25),
      armorPaint,
    );
    
    // Large shield (left side)
    final shieldPaint = Paint()..color = const Color(0xFF4169E1);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 25, centerY - 5, 15, 20),
      shieldPaint,
    );
    
    // Shield cross (heraldic symbol)
    final crossPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawLine(
      Offset(centerX - 17, centerY - 2),
      Offset(centerX - 17, centerY + 12),
      crossPaint,
    );
    
    canvas.drawLine(
      Offset(centerX - 23, centerY + 5),
      Offset(centerX - 11, centerY + 5),
      crossPaint,
    );
    
    // Large sword (right side)
    final swordPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    
    canvas.drawLine(
      Offset(centerX + 15, centerY - 10),
      Offset(centerX + 15, centerY + 20),
      swordPaint,
    );
    
    // Sword hilt
    final hiltPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRect(
      Rect.fromLTWH(centerX + 10, centerY + 18, 10, 6),
      hiltPaint,
    );
  }
  
  void _drawWizard(Canvas canvas) {
    // Draw simple wizard (20-30 hit points)
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    
    // Background with mystical gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF4B0082).withValues(alpha: 0.9),
        const Color(0xFF2E0854).withValues(alpha: 0.8),
      ],
    );
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    
    // Large wizard head
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(centerX, centerY - 5), 12, headPaint);
    
    // Large pointed wizard hat (main feature)
    final hatPaint = Paint()..color = const Color(0xFF191970);
    final hatPath = Path();
    hatPath.moveTo(centerX - 15, centerY - 5);
    hatPath.lineTo(centerX, centerY - 30);
        hatPath.lineTo(centerX + 15, centerY - 5);
    hatPath.close();
    canvas.drawPath(hatPath, hatPaint);
    
    // Hat brim
    final brimPaint = Paint()..color = const Color(0xFF191970);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 18, centerY - 8, 36, 8),
      brimPaint,
    );
    
    // Large golden star on hat (distinctive feature)
    final starPaint = Paint()..color = const Color(0xFFFFD700);
    _drawStar(canvas, centerX, centerY - 20, 4, starPaint);
    
    // Long white beard (very visible)
    final beardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    
    canvas.drawLine(
      Offset(centerX, centerY + 5),
      Offset(centerX, centerY + 20),
      beardPaint,
    );
    
    // Purple robe body
    final robePaint = Paint()..color = const Color(0xFF9370DB);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, centerY + 8, 24, 25),
      robePaint,
    );
    
    // Large magical staff (right side)
    final staffPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    
    canvas.drawLine(
      Offset(centerX + 15, centerY - 10),
      Offset(centerX + 15, centerY + 25),
      staffPaint,
    );
    
    // Large crystal orb on staff (very visible)
    final orbPaint = Paint()..color = const Color(0xFF00FFFF);
    canvas.drawCircle(Offset(centerX + 15, centerY - 10), 8, orbPaint);
    
    // Orb glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(Offset(centerX + 15, centerY - 10), 12, glowPaint);
    
    // Simple eyes (for character recognition)
    final eyePaint = Paint()..color = const Color(0xFF4169E1);
    canvas.drawCircle(Offset(centerX - 4, centerY - 8), 2, eyePaint);
    canvas.drawCircle(Offset(centerX + 4, centerY - 8), 2, eyePaint);
  }
  
  void _drawStar(Canvas canvas, double x, double y, double size, Paint paint) {
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final outerRadius = size;
      final innerRadius = size * 0.4;
      
      if (i == 0) {
        starPath.moveTo(
          x + outerRadius * cos(angle),
          y + outerRadius * sin(angle),
        );
      } else {
        starPath.lineTo(
          x + outerRadius * cos(angle),
          y + outerRadius * sin(angle),
        );
      }
      
      final innerAngle = angle + 3.14159 / 5;
      starPath.lineTo(
        x + innerRadius * cos(innerAngle),
        y + innerRadius * sin(innerAngle),
      );
    }
    starPath.close();
    canvas.drawPath(starPath, paint);
  }
  
  void _drawSparkle(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawLine(Offset(x - 2, y), Offset(x + 2, y), paint);
    canvas.drawLine(Offset(x, y - 2), Offset(x, y + 2), paint);
    canvas.drawLine(Offset(x - 1.5, y - 1.5), Offset(x + 1.5, y + 1.5), paint);
    canvas.drawLine(Offset(x + 1.5, y - 1.5), Offset(x - 1.5, y + 1.5), paint);
  }
  
  void _drawDragon(Canvas canvas) {
    // Draw simple dragon (30+ hit points) - scaled to fill brick area
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final centerX = size.x * 0.5;
    final centerY = size.y * 0.5;
    final scale = 1.4; // Scale factor to make character fill the brick area
    
    // Background with fiery gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B0000).withValues(alpha: 0.9),
        const Color(0xFF4B0000).withValues(alpha: 0.8),
      ],
    );
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    
    // Large dragon wings (main feature)
    final wingPaint = Paint()..color = const Color(0xFF8B0000);
    
    // Left wing
    final leftWingPath = Path();
    leftWingPath.moveTo(centerX - 10 * scale, centerY);
    leftWingPath.lineTo(centerX - 25 * scale, centerY - 15 * scale);
    leftWingPath.lineTo(centerX - 20 * scale, centerY + 10 * scale);
    leftWingPath.close();
    canvas.drawPath(leftWingPath, wingPaint);
    
    // Right wing
    final rightWingPath = Path();
    rightWingPath.moveTo(centerX + 10 * scale, centerY);
    rightWingPath.lineTo(centerX + 25 * scale, centerY - 15 * scale);
    rightWingPath.lineTo(centerX + 20 * scale, centerY + 10 * scale);
    rightWingPath.close();
    canvas.drawPath(rightWingPath, wingPaint);
    
    // Large dragon body
    final bodyPaint = Paint()..color = const Color(0xFFDC143C);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 12 * scale, centerY - 5 * scale, 24 * scale, 20 * scale),
      bodyPaint,
    );
    
    // Large dragon head
    final headPaint = Paint()..color = const Color(0xFFDC143C);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 8 * scale, centerY - 15 * scale, 16 * scale, 12 * scale),
      headPaint,
    );
    
    // Large fierce eyes (very visible)
    final eyePaint = Paint()..color = const Color(0xFFFFFF00);
    canvas.drawOval(
      Rect.fromLTWH(centerX - 6 * scale, centerY - 12 * scale, 4 * scale, 3 * scale),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(centerX + 2 * scale, centerY - 12 * scale, 4 * scale, 3 * scale),
      eyePaint,
    );
    
    // Eye pupils
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawOval(
      Rect.fromLTWH(centerX - 5 * scale, centerY - 11 * scale, 2 * scale, 1 * scale),
      pupilPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(centerX + 3 * scale, centerY - 11 * scale, 2 * scale, 1 * scale),
      pupilPaint,
    );
    
    // Large horns (distinctive feature)
    final hornPaint = Paint()..color = const Color(0xFF2F2F2F);
    
    // Left horn
    final leftHornPath = Path();
    leftHornPath.moveTo(centerX - 6 * scale, centerY - 15 * scale);
    leftHornPath.lineTo(centerX - 10 * scale, centerY - 25 * scale);
    leftHornPath.lineTo(centerX - 4 * scale, centerY - 13 * scale);
    leftHornPath.close();
    canvas.drawPath(leftHornPath, hornPaint);
    
    // Right horn
    final rightHornPath = Path();
    rightHornPath.moveTo(centerX + 6 * scale, centerY - 15 * scale);
    rightHornPath.lineTo(centerX + 10 * scale, centerY - 25 * scale);
    rightHornPath.lineTo(centerX + 4 * scale, centerY - 13 * scale);
    rightHornPath.close();
    canvas.drawPath(rightHornPath, hornPaint);
    
    // Large fire breath (very visible)
     final firePaint = Paint()..color = const Color(0xFFFF4500);
     for (int i = 0; i < 5; i++) {
       canvas.drawCircle(
         Offset(centerX + 10 * scale + i * 4 * scale, centerY - 8 * scale + (i % 2) * 2 * scale),
         (6 - i).toDouble() * scale,
         firePaint,
       );
     }
    
    // Fire glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(
      Offset(centerX + 15 * scale, centerY - 8 * scale),
      15 * scale,
      glowPaint,
    );
  }
  
  void _drawDragonWings(Canvas canvas, double centerX, double topY) {
    // Powerful dragon wings with membrane details
    final wingGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF8B0000), // Dark red
        const Color(0xFF654321), // Brown
        const Color(0xFF2F1B14), // Dark brown
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final wingPaint = Paint()
      ..shader = wingGradient.createShader(Rect.fromLTWH(centerX - 20, topY, 40, 25));
    
    // Left wing
    final leftWingPath = Path();
    leftWingPath.moveTo(centerX - 8, topY + 12);
    leftWingPath.lineTo(centerX - 25, topY + 5);
    leftWingPath.lineTo(centerX - 30, topY + 15);
    leftWingPath.lineTo(centerX - 20, topY + 25);
    leftWingPath.lineTo(centerX - 10, topY + 20);
    leftWingPath.close();
    
    canvas.drawPath(leftWingPath, wingPaint);
    
    // Right wing
    final rightWingPath = Path();
    rightWingPath.moveTo(centerX + 8, topY + 12);
    rightWingPath.lineTo(centerX + 25, topY + 5);
    rightWingPath.lineTo(centerX + 30, topY + 15);
    rightWingPath.lineTo(centerX + 20, topY + 25);
    rightWingPath.lineTo(centerX + 10, topY + 20);
    rightWingPath.close();
    
    canvas.drawPath(rightWingPath, wingPaint);
    
    // Wing membrane details
    final membranePaint = Paint()
      ..color = const Color(0xFF654321).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Left wing membranes
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(centerX - 8, topY + 12),
        Offset(centerX - 15 - i * 3, topY + 8 + i * 4),
        membranePaint,
      );
    }
    
    // Right wing membranes
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(centerX + 8, topY + 12),
        Offset(centerX + 15 + i * 3, topY + 8 + i * 4),
        membranePaint,
      );
    }
  }
  
  void _drawDragonBody(Canvas canvas, double centerX, double topY) {
    // Muscular dragon body with scales
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.2,
      colors: [
        const Color(0xFFDC143C), // Crimson
        const Color(0xFF8B0000), // Dark red
        const Color(0xFF4B0000), // Very dark red
        const Color(0xFF2F0000), // Almost black red
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    
    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromLTWH(centerX - 12, topY + 15, 24, 25));
    
    // Main body
    canvas.drawOval(
      Rect.fromLTWH(centerX - 12, topY + 15, 24, 25),
      bodyPaint,
    );
    
    // Chest armor/scales
    final scalePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Scale pattern on chest
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 3; col++) {
        final x = centerX - 6 + col * 4;
        final y = topY + 18 + row * 4;
        
        canvas.drawOval(
          Rect.fromLTWH(x, y, 3, 2),
          scalePaint,
        );
      }
    }
    
    // Belly highlight
    final bellyPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withValues(alpha: 0.4);
    
    canvas.drawOval(
      Rect.fromLTWH(centerX - 8, topY + 20, 16, 15),
      bellyPaint,
    );
  }
  
  void _drawDragonHead(Canvas canvas, double centerX, double topY) {
    // Fierce dragon head with horns and spikes
    final headGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
      colors: [
        const Color(0xFFDC143C), // Crimson
        const Color(0xFF8B0000), // Dark red
        const Color(0xFF4B0000), // Very dark red
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final headPaint = Paint()
      ..shader = headGradient.createShader(Rect.fromLTWH(centerX - 10, topY + 2, 20, 15));
    
    // Main head
    canvas.drawOval(
      Rect.fromLTWH(centerX - 10, topY + 2, 20, 15),
      headPaint,
    );
    
    // Snout
    final snoutPaint = Paint()
      ..color = const Color(0xFF8B0000);
    
    canvas.drawOval(
      Rect.fromLTWH(centerX - 6, topY + 8, 12, 8),
      snoutPaint,
    );
    
    // Fierce eyes
    final eyePaint = Paint()
      ..color = const Color(0xFFFFFF00); // Bright yellow
    
    canvas.drawOval(
      Rect.fromLTWH(centerX - 6, topY + 5, 4, 3),
      eyePaint,
    );
    
    canvas.drawOval(
      Rect.fromLTWH(centerX + 2, topY + 5, 4, 3),
      eyePaint,
    );
    
    // Eye pupils
    final pupilPaint = Paint()
      ..color = Colors.black;
    
    canvas.drawOval(
      Rect.fromLTWH(centerX - 5, topY + 6, 2, 1),
      pupilPaint,
    );
    
    canvas.drawOval(
      Rect.fromLTWH(centerX + 3, topY + 6, 2, 1),
      pupilPaint,
    );
    
    // Horns
    final hornPaint = Paint()
      ..color = const Color(0xFF2F2F2F); // Dark gray
    
    // Left horn
    final leftHornPath = Path();
    leftHornPath.moveTo(centerX - 8, topY + 4);
    leftHornPath.lineTo(centerX - 12, topY - 5);
    leftHornPath.lineTo(centerX - 6, topY + 2);
    leftHornPath.close();
    
    canvas.drawPath(leftHornPath, hornPaint);
    
    // Right horn
    final rightHornPath = Path();
    rightHornPath.moveTo(centerX + 8, topY + 4);
    rightHornPath.lineTo(centerX + 12, topY - 5);
    rightHornPath.lineTo(centerX + 6, topY + 2);
    rightHornPath.close();
    
    canvas.drawPath(rightHornPath, hornPaint);
    
    // Nostrils
    final nostrilPaint = Paint()
      ..color = Colors.black;
    
    canvas.drawOval(
      Rect.fromLTWH(centerX - 3, topY + 11, 2, 1),
      nostrilPaint,
    );
    
    canvas.drawOval(
      Rect.fromLTWH(centerX + 1, topY + 11, 2, 1),
      nostrilPaint,
    );
    
    // Teeth/fangs
    final fangPaint = Paint()
      ..color = Colors.white;
    
    // Upper fangs
    final leftFangPath = Path();
    leftFangPath.moveTo(centerX - 4, topY + 13);
    leftFangPath.lineTo(centerX - 3, topY + 16);
    leftFangPath.lineTo(centerX - 2, topY + 13);
    leftFangPath.close();
    
    canvas.drawPath(leftFangPath, fangPaint);
    
    final rightFangPath = Path();
    rightFangPath.moveTo(centerX + 2, topY + 13);
    rightFangPath.lineTo(centerX + 3, topY + 16);
    rightFangPath.lineTo(centerX + 4, topY + 13);
    rightFangPath.close();
    
    canvas.drawPath(rightFangPath, fangPaint);
  }
  
  void _drawDragonTail(Canvas canvas, double centerX, double topY) {
    // Long serpentine tail with spikes
    final tailPaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    
    // Tail curve
    final tailPath = Path();
    tailPath.moveTo(centerX, topY + 35);
    tailPath.quadraticBezierTo(
      centerX + 15, topY + 45,
      centerX + 25, topY + 40,
    );
    
    canvas.drawPath(tailPath, tailPaint);
    
    // Tail spikes
    final spikePaint = Paint()
      ..color = const Color(0xFF2F2F2F);
    
    for (int i = 0; i < 4; i++) {
      final x = centerX + 5 + i * 5;
      final y = topY + 38 + i * 2;
      
      final spikePath = Path();
      spikePath.moveTo(x - 2, y);
      spikePath.lineTo(x, y - 4);
      spikePath.lineTo(x + 2, y);
      spikePath.close();
      
      canvas.drawPath(spikePath, spikePaint);
    }
  }
  
  void _drawDragonFire(Canvas canvas, double centerX, double topY) {
    // Intense dragon fire breath
    final fireColors = [
      const Color(0xFFFFFFFF), // White hot center
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFFFF8C00), // Dark orange
      const Color(0xFFFF4500), // Orange red
      const Color(0xFFDC143C), // Crimson
    ];
    
    // Multiple fire particles
    for (int i = 0; i < 8; i++) {
      final distance = i * 4;
      final size = 6 - i * 0.5;
      final colorIndex = (i * fireColors.length / 8).floor().clamp(0, fireColors.length - 1);
      
      final firePaint = Paint()
        ..color = fireColors[colorIndex].withValues(alpha: 0.8 - i * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      // Main fire stream
      canvas.drawCircle(
        Offset(centerX + 12 + distance, topY + 10 + (i % 2) * 2),
        size,
        firePaint,
      );
      
      // Secondary fire particles
      if (i < 5) {
        canvas.drawCircle(
          Offset(centerX + 10 + distance, topY + 8 + (i % 3)),
          size * 0.6,
          firePaint,
        );
        
        canvas.drawCircle(
          Offset(centerX + 14 + distance, topY + 12 + (i % 2)),
          size * 0.4,
          firePaint,
        );
      }
    }
    
    // Fire glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(
      Offset(centerX + 20, topY + 10),
      15,
      glowPaint,
    );
  }
  
  void _drawDragonDetails(Canvas canvas, double centerX, double topY) {
    // Additional dragon details like claws and spikes
    final clawPaint = Paint()
      ..color = const Color(0xFF2F2F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Front claws
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(centerX - 8 + i * 2, topY + 35),
        Offset(centerX - 9 + i * 2, topY + 40),
        clawPaint,
      );
      
      canvas.drawLine(
        Offset(centerX + 5 + i * 2, topY + 35),
        Offset(centerX + 4 + i * 2, topY + 40),
        clawPaint,
      );
    }
    
    // Back spikes
    final backSpikePaint = Paint()
      ..color = const Color(0xFF2F2F2F);
    
    for (int i = 0; i < 5; i++) {
      final x = centerX - 10 + i * 4;
      final y = topY + 15;
      
      final spikePath = Path();
      spikePath.moveTo(x - 1, y);
      spikePath.lineTo(x, y - 3);
      spikePath.lineTo(x + 1, y);
      spikePath.close();
      
      canvas.drawPath(spikePath, backSpikePaint);
    }
    
    // Dragon aura/power emanation
    final auraPaint = Paint()
      ..color = const Color(0xFFDC143C).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(
      Offset(centerX, topY + 20),
      20,
      auraPaint,
    );
  }
  
  void _drawHitPointsText(Canvas canvas) {
    // Draw background circle for better visibility
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // Draw background circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      bgPaint,
    );
    
    // Draw border circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      borderPaint,
    );
    
    // Draw text shadow first
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: hitPoints.toString(),
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.8),
          fontSize: 20,
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
          fontSize: 20,
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