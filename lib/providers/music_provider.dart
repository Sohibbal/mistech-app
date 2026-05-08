import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicEnabled = true;
  static const String _musicKey = 'bg_music_enabled';

  MusicProvider() {
    _init();
  }

  bool get isMusicEnabled => _isMusicEnabled;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool(_musicKey) ?? true;
    
    // Set looping
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    
    if (_isMusicEnabled) {
      await _playMusic();
    }
  }

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, _isMusicEnabled);

    if (_isMusicEnabled) {
      await _playMusic();
    } else {
      await _audioPlayer.stop();
    }
    notifyListeners();
  }

  Future<void> _playMusic() async {
    try {
      // Pastikan file ini ada di assets/audio/bg_music.mp3
      await _audioPlayer.play(AssetSource('audio/bg_music.mp3'));
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
