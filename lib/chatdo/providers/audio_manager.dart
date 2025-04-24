// audio_manager.dart

import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioPlayer? _player;

  AudioManager._internal();

  Future<void> play(String assetPath, {double volume = 0.2}) async {
    try {
      await _player?.dispose();
      _player = AudioPlayer();
      await _player!.setAudioSource(AudioSource.asset(assetPath));
      await _player!.setVolume(0.0);
      await _player!.load();
      await _player!.play();
      await fadeIn(volume: volume);
    } catch (e) {
      print('🎵 AudioManager play error: $e');
    }
  }

  Future<void> fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    if (_player == null) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: 100);
    final initialVolume = await _player!.volume;
    final step = initialVolume / steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);
      _player!.setVolume((initialVolume - step * i).clamp(0.0, 1.0));
    }

    await _player!.stop();
  }

  Future<void> fadeIn({double volume = 0.2, Duration duration = const Duration(seconds: 2)}) async {
    if (_player == null) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: 100);
    final step = volume / steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);
      _player!.setVolume((step * (i + 1)).clamp(0.0, 1.0));
    }
  }

  Future<void> stop() async {
    await _player?.stop();
  }
}
