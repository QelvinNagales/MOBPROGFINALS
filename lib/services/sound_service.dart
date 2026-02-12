import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for playing notification sounds
/// Handles chat notifications and default notifications with user preferences
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Sound file paths
  static const String _chatNotifSound = 'assets/sounds/chat-notif.mp3';
  static const String _defaultNotifSound = 'assets/sounds/default-notif.mp3';
  
  // Preference keys
  static const String _soundEnabledKey = 'notification_sound_enabled';
  static const String _chatSoundEnabledKey = 'chat_sound_enabled';
  
  bool _soundEnabled = true;
  bool _chatSoundEnabled = true;
  bool _initialized = false;

  /// Initialize the sound service and load preferences
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _chatSoundEnabled = prefs.getBool(_chatSoundEnabledKey) ?? true;
      
      // Set low latency mode for quick playback
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      _initialized = true;
    } catch (e) {
      print('Error initializing SoundService: $e');
    }
  }

  /// Check if sounds are enabled
  bool get isSoundEnabled => _soundEnabled;
  bool get isChatSoundEnabled => _chatSoundEnabled;

  /// Enable or disable all notification sounds
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Enable or disable chat notification sounds specifically
  Future<void> setChatSoundEnabled(bool enabled) async {
    _chatSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatSoundEnabledKey, enabled);
  }

  /// Play chat notification sound
  Future<void> playChatNotification() async {
    if (!_soundEnabled || !_chatSoundEnabled) return;
    await _playSound(_chatNotifSound);
  }

  /// Play default notification sound
  Future<void> playDefaultNotification() async {
    if (!_soundEnabled) return;
    await _playSound(_defaultNotifSound);
  }

  /// Internal method to play a sound file
  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.stop(); // Stop any currently playing sound
      await _audioPlayer.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

// Global instance for easy access
final soundService = SoundService();
