// audio_manager.dart (페이드 아웃만 적용)
import 'package:flutter/foundation.dart'; // VoidCallback 정의돼 있음
import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager instance = AudioManager();
  AudioPlayer? _player;

  Future<void> play(String assetPath, {double volume = 1.0}) async {
    try {
      final oldPlayer = _player;
      _player = AudioPlayer();

      _player!.playerStateStream.listen((state) {
        print("🎧 상태 변화: ${state.processingState}, playing: ${state.playing}");
      });

      await _player!.setAudioSource(AudioSource.asset(assetPath));
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(volume);
      await _player!.load();

      print('🎧 재생 준비됨: $assetPath');
      await _player!.play();
      print("✅ play() 호출됨");

      await oldPlayer?.stop();
      await oldPlayer?.dispose();
      print('🌊 디스포즈 완료');
    } catch (e, stackTrace) {
      print('🎵 AudioManager play error: $e');
      print('📍 STACK: $stackTrace');
    }
  }

  Future<void> stop() async {
    if (_player == null) return;
    await _fadeOut();
    await _player!.stop();
  }

    Future<void> fadeOutAndPlay(
        String assetPath, {
          double volume = 1.0,
          VoidCallback? onComplete, // ✅ 추가
        }) async {
      if (_player != null) {
        await _fadeOut();
        await _player!.stop();
        await _player!.dispose();
      }
    _player = AudioPlayer();
    await _player!.setAudioSource(AudioSource.asset(assetPath));
    await _player!.setLoopMode(LoopMode.off);
      await _player!.setVolume(volume); // 시작은 0으로 시작해서
    await _player!.load();
    await _player!.play();
// ✅ 재생 완료 감지 후 콜백 실행
      _player!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          onComplete?.call();
        }
      });
  }


  Future<void> _fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    if (_player == null) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: 100);
    final initialVolume = await _player!.volume;
    final step = initialVolume / steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);
      _player?.setVolume((initialVolume - step * i).clamp(0.0, 1.0));
    }
  }
}
