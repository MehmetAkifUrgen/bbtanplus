import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _hasSavedGame = false;
  final GameState _gameState = GameState();
  
  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }
  
  Future<void> _checkSavedGame() async {
    final hasSaved = await _gameState.hasSavedGame();
    setState(() {
      _hasSavedGame = hasSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              // Game Title
              Text(
                'CRYSTAL\nBREAKER 3D',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              // Menu Buttons
              if (_hasSavedGame) ...[
                _buildMenuButton(
                  context,
                  'DEVAM ET',
                  Icons.play_circle_filled,
                  () async {
                    final success = await _gameState.loadGameState();
                    if (success && mounted) {
                      Navigator.pushNamed(context, '/game', arguments: {
                        'resumeGame': true,
                        'gameState': _gameState,
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
              
             
            
              
              
              
              _buildMenuButton(
                context,
                'YENİ OYUN',
                Icons.play_arrow,
                () {
                  _gameState.clearSavedGame().then((_) {
                    if (mounted) {
                      Navigator.pushNamed(context, '/game');
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'SETTINGS',
                Icons.settings,
                () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(height: 20),
              
             
              
              _buildMenuButton(
                context,
                'EXIT',
                Icons.exit_to_app,
                () => Navigator.of(context).pop(),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.transparent,
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
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}