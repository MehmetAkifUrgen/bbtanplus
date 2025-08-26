import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.7;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    _soundVolume = prefs.getDouble('sound_volume') ?? 1.0;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.7;
    
    await _musicPlayer.setVolume(_musicVolume);
    await _sfxPlayer.setVolume(_soundVolume);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
    
    if (!enabled) {
      await _musicPlayer.stop();
    }
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume;
    await _sfxPlayer.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', volume);
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    await _musicPlayer.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', volume);
  }

  Future<void> playSound(String soundName) async {
    if (!_soundEnabled) return;
    
    // Audio files are not available, skip playing sounds
    // try {
    //   await _sfxPlayer.play(AssetSource('audio/$soundName.mp3'));
    // } catch (e) {
    //   print('Error playing sound $soundName: $e');
    // }
  }

  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled) return;
    
    // Audio files are not available, skip playing music
    // try {
    //   await _musicPlayer.play(AssetSource('audio/background_music.mp3'));
    //   await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    // } catch (e) {
    //   print('Error playing background music: $e');
    // }
  }

  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_musicEnabled) {
      await _musicPlayer.resume();
    }
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}