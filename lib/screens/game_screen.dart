import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/crystal_breaker_game.dart';
import '../models/level.dart';

class GameScreen extends StatefulWidget {
  final Level? selectedLevel;
  
  const GameScreen({super.key, this.selectedLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CrystalBreakerGame game;
  bool isPaused = false;
  bool isGameLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  Future<void> _initializeGame() async {
    game = CrystalBreakerGame(selectedLevel: widget.selectedLevel);
    
    // Wait for game to be added to widget tree and loaded
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      setState(() {
        isGameLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game Widget with Gesture Detection
          GestureDetector(
            onTapDown: (details) {
              if (isGameLoaded && !game.ballInMotion && !game.isAiming) {
                game.startAiming(details.localPosition);
              }
            },
            onTapUp: (details) {
              if (isGameLoaded && game.isAiming) {
                game.launchBall();
              }
            },
            onPanStart: (details) {
              if (isGameLoaded && !game.ballInMotion) {
                game.startAiming(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (isGameLoaded && game.isAiming) {
                game.updateAiming(details.localPosition);
              }
            },
            onPanEnd: (details) {
              if (isGameLoaded && game.isAiming) {
                game.launchBall();
              }
            },
            child: isGameLoaded 
                ? GameWidget(game: game)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1a1a2e),
                          Color(0xFF16213e),
                          Color(0xFF0f3460),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const CircularProgressIndicator(
                              color: Color(0xFF4facfe),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'CRYSTAL BREAKER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Loading Game...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // UI Overlay
          if (isGameLoaded)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${game.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pause Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _togglePause,
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Football Player Character
          if (isGameLoaded)
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: Container(
                width: 60,
                height: 80,
                child: CustomPaint(
                  painter: FootballPlayerPainter(),
                ),
              ),
            ),
          
          // Pause Overlay
          if (isPaused)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.blue.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      _buildPauseButton(
                        'RESUME',
                        Icons.play_arrow,
                        const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                        _togglePause,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildPauseButton(
                        'QUIT GAME',
                        Icons.exit_to_app,
                        const LinearGradient(
                          colors: [Color(0xFFff6b6b), Color(0xFFee5a52)],
                        ),
                        () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        game.pauseEngine();
      } else {
        game.resumeEngine();
      }
    });
  }

  Widget _buildPauseButton(
    String text,
    IconData icon,
    Gradient gradient,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    game.detach();
    super.dispose();
  }
}

class FootballPlayerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw head (circle)
    paint.color = const Color(0xFFFFDBB5); // Skin color
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.2),
      size.width * 0.15,
      paint,
    );
    
    // Draw body (rectangle)
    paint.color = Colors.blue; // Jersey color
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.3,
          size.height * 0.3,
          size.width * 0.4,
          size.height * 0.4,
        ),
        const Radius.circular(5),
      ),
      paint,
    );
    
    // Draw arms
    paint.color = const Color(0xFFFFDBB5);
    paint.strokeWidth = size.width * 0.08;
    paint.strokeCap = StrokeCap.round;
    
    // Left arm
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.1, size.height * 0.55),
      paint,
    );
    
    // Right arm
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.55),
      paint,
    );
    
    // Draw legs
    paint.color = Colors.white; // Shorts color
    paint.strokeWidth = size.width * 0.12;
    
    // Left leg
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.35, size.height * 0.9),
      paint,
    );
    
    // Right leg
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.7),
      Offset(size.width * 0.65, size.height * 0.9),
      paint,
    );
    
    // Draw football boots
    paint.color = Colors.black;
    paint.style = PaintingStyle.fill;
    
    // Left boot
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.85,
        size.width * 0.2,
        size.height * 0.1,
      ),
      paint,
    );
    
    // Right boot
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.85,
        size.width * 0.2,
        size.height * 0.1,
      ),
      paint,
    );
    
    // Draw hair
    paint.color = Colors.brown;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.15),
      size.width * 0.12,
      paint,
    );
    
    // Draw eyes
    paint.color = Colors.black;
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.18),
      size.width * 0.02,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.18),
      size.width * 0.02,
      paint,
    );
    
    // Draw smile
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.2,
        size.width * 0.1,
        size.height * 0.05,
      ),
      0,
      3.14159,
    );
    canvas.drawPath(smilePath, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}