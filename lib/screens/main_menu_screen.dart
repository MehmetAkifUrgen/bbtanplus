import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              // Game Title
              const Text(
                'CRYSTAL\nBREAKER 3D',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              // Menu Buttons
              _buildMenuButton(
                context,
                'LEVELS',
                Icons.grid_view,
                () => Navigator.pushNamed(context, '/levels'),
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'MISSIONS',
                Icons.assignment,
                () => Navigator.pushNamed(context, '/missions'),
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'QUICK PLAY',
                Icons.play_arrow,
                () => Navigator.pushNamed(context, '/game'),
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                'CUSTOMIZATION',
                Icons.palette,
                () => Navigator.pushNamed(context, '/customization'),
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
                'HIGH SCORES',
                Icons.leaderboard,
                () => Navigator.pushNamed(context, '/score'),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
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