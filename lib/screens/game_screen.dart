import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:math';
import '../game/crystal_breaker_game.dart';
import '../models/level.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  final Level? selectedLevel;
  final bool resumeGame;
  final GameState? gameState;
  
  const GameScreen({
    super.key, 
    this.selectedLevel,
    this.resumeGame = false,
    this.gameState,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late CrystalBreakerGame game;
  bool isGameLoaded = false;
  bool isPaused = false;
  late AnimationController _staffAnimationController;
  late Animation<double> _staffSwingAnimation;
  bool _isStaffSwinging = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
    // Initialize staff swing animation
    _staffAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _staffSwingAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3, // 0.3 radians swing
    ).animate(CurvedAnimation(
      parent: _staffAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we're resuming a game from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['resumeGame'] == true) {
      final gameState = args['gameState'] as GameState?;
      if (gameState != null) {
        _waitForGameLoadAndResume(gameState);
      }
    }
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
  
  Future<void> _waitForGameLoadAndResume(GameState gameState) async {
    // Wait for game to be fully loaded before resuming
    while (!isGameLoaded) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // Additional wait to ensure all managers are initialized
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Double check that game is still loaded and mounted
    if (isGameLoaded && mounted) {
      _resumeGame(gameState);
    }
  }
  
  Future<void> _resumeGame(GameState gameState) async {
    // Resume game with saved state
    if (isGameLoaded) {
      // Core state sync
      // Attach state then delegate restoration for consistency
      game.gameState = gameState;
      game.restoreFromGameState(gameState);
      // Trigger UI rebuild for updated values
      setState(() {});
    }
  }
  
  Future<void> _saveAndQuit() async {
    if (isGameLoaded) {
      // Ensure latest state captured
      game.captureGameState();
      await game.gameState.saveGameState();
      if (mounted) {
        Navigator.of(context).pop();
      }
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
                _triggerStaffSwing();
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
                _triggerStaffSwing();
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
              top: 30,
              left: 20,
              right: 20,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Score Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${game.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Level Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.layers,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lv ${game.currentLevel?.levelNumber ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lives Display
                   Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 10,
                       vertical: 6,
                     ),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: game.isBurning 
                             ? [Colors.red.shade600, Colors.orange.shade600]
                             : [Color(0xFF43e97b), Color(0xFF38f9d7)],
                       ),
                       borderRadius: BorderRadius.circular(15),
                       boxShadow: [
                         BoxShadow(
                           color: (game.isBurning ? Colors.red : Colors.green).withValues(alpha: 0.3),
                           blurRadius: 6,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                           game.isBurning ? Icons.local_fire_department : Icons.favorite,
                           color: Colors.white,
                           size: 14,
                         ),
                         const SizedBox(width: 4),
                         Text(
                           '${game.playerLives}',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                   ),
                  
                  // Ball Count Display
                   Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 10,
                       vertical: 6,
                     ),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                       ),
                       borderRadius: BorderRadius.circular(15),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.blue.withValues(alpha: 0.3),
                           blurRadius: 6,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(
                           Icons.sports_baseball,
                           color: Colors.white,
                           size: 14,
                         ),
                         const SizedBox(width: 4),
                         Text(
                           '${game.ballsRemaining}',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                   ),
                  
                  // Pause Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _togglePause,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Gandalf Character (Ana Karakter)
          if (isGameLoaded)
            Positioned(
              bottom: 15,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Container(
                width: 100,
                height: 80,
                child: Transform.rotate(
                  angle: _staffSwingAnimation.value * 0.1, // Hafif sallanma efekti
                  child: Image.asset(
                    'assets/images/gandalf-removebg-preview.png',
                    width: 100,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
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
                        'KAYDET VE ÇIK',
                        Icons.save,
                        const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        _saveAndQuit,
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

  void _triggerStaffSwing() {
    if (!_isStaffSwinging) {
      setState(() {
        _isStaffSwinging = true;
      });
      _staffAnimationController.forward().then((_) {
        _staffAnimationController.reverse().then((_) {
          setState(() {
            _isStaffSwinging = false;
          });
        });
      });
    }
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
    _staffAnimationController.dispose();
    game.detach();
    super.dispose();
  }
}