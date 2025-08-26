import 'package:flutter/material.dart';
import '../services/theme_manager.dart';
import '../services/audio_manager.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  late ThemeManager themeManager;
  late AudioManager audioManager;
  GameTheme selectedTheme = GameTheme.classic;
  bool soundEnabled = true;
  bool musicEnabled = true;
  double ballSpeed = 1.0;
  double gameVolume = 0.7;

  @override
  void initState() {
    super.initState();
    themeManager = ThemeManager();
    audioManager = AudioManager();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await themeManager.initialize();
    setState(() {
      selectedTheme = themeManager.currentTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColors = themeManager.getThemeColors(selectedTheme);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customization'),
        backgroundColor: currentColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentColors.background,
              currentColors.surface,
              currentColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Selection
                _buildSectionTitle('Visual Themes'),
                const SizedBox(height: 16),
                _buildThemeGrid(),
                const SizedBox(height: 32),
                
                // Audio Settings
                _buildSectionTitle('Audio Settings'),
                const SizedBox(height: 16),
                _buildAudioSettings(currentColors),
                const SizedBox(height: 32),
                
                // Game Settings
                _buildSectionTitle('Game Settings'),
                const SizedBox(height: 16),
                _buildGameSettings(currentColors),
                const SizedBox(height: 32),
                
                // Apply Button
                Center(
                  child: ElevatedButton(
                    onPressed: _applySettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Apply Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: GameTheme.values.length,
      itemBuilder: (context, index) {
        final theme = GameTheme.values[index];
        return _buildThemeCard(theme);
      },
    );
  }

  Widget _buildThemeCard(GameTheme theme) {
    final colors = themeManager.getThemeColors(theme);
    final isSelected = selectedTheme == theme;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTheme = theme;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.secondary],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Theme preview
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colors.background,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.ballColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 12,
                        height: 6,
                        color: colors.normalBrick,
                      ),
                      Container(
                        width: 12,
                        height: 6,
                        color: colors.explosiveBrick,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              themeManager.getThemeName(theme),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              themeManager.getThemeDescription(theme),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Sound Effects',
            soundEnabled,
            (value) => setState(() => soundEnabled = value),
            Icons.volume_up,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Background Music',
            musicEnabled,
            (value) => setState(() => musicEnabled = value),
            Icons.music_note,
          ),
          const SizedBox(height: 16),
          _buildSliderTile(
            'Master Volume',
            gameVolume,
            (value) => setState(() => gameVolume = value),
            Icons.volume_down,
            Icons.volume_up,
          ),
        ],
      ),
    );
  }

  Widget _buildGameSettings(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSliderTile(
            'Ball Speed',
            ballSpeed,
            (value) => setState(() => ballSpeed = value),
            Icons.slow_motion_video,
            Icons.fast_forward,
            min: 0.5,
            max: 2.0,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
    IconData minIcon,
    IconData maxIcon, {
    double min = 0.0,
    double max = 1.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(minIcon, color: Colors.white70, size: 20),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: 20,
                onChanged: onChanged,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            Icon(maxIcon, color: Colors.white70, size: 20),
          ],
        ),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _applySettings() async {
    // Apply theme
    await themeManager.setTheme(selectedTheme);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}