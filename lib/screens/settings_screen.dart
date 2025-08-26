import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool vibrationEnabled = true;
  double soundVolume = 0.8;
  double musicVolume = 0.6;
  String selectedTheme = 'Space';
  
  final List<String> themes = ['Space', 'Neon', 'Classic', 'Crystal'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      musicEnabled = prefs.getBool('musicEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      soundVolume = prefs.getDouble('soundVolume') ?? 0.8;
      musicVolume = prefs.getDouble('musicVolume') ?? 0.6;
      selectedTheme = prefs.getString('selectedTheme') ?? 'Space';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setDouble('soundVolume', soundVolume);
    await prefs.setDouble('musicVolume', musicVolume);
    await prefs.setString('selectedTheme', selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'SETTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 50), // Balance the back button
                  ],
                ),
              ),
              
              // Settings List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSectionTitle('AUDIO'),
                    _buildSwitchTile(
                      'Sound Effects',
                      soundEnabled,
                      (value) {
                        setState(() {
                          soundEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSwitchTile(
                      'Background Music',
                      musicEnabled,
                      (value) {
                        setState(() {
                          musicEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSliderTile(
                      'Sound Volume',
                      soundVolume,
                      (value) {
                        setState(() {
                          soundVolume = value;
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSliderTile(
                      'Music Volume',
                      musicVolume,
                      (value) {
                        setState(() {
                          musicVolume = value;
                        });
                        _saveSettings();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle('GAMEPLAY'),
                    _buildSwitchTile(
                      'Vibration',
                      vibrationEnabled,
                      (value) {
                        setState(() {
                          vibrationEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle('APPEARANCE'),
                    _buildThemeSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: themes.map((theme) {
              final isSelected = theme == selectedTheme;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTheme = theme;
                  });
                  _saveSettings();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    theme,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}