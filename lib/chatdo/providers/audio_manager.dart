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
    await _player!.dispose();
  }

  Future<void> fadeOutAndPlay(
      String assetPath, {
        double volume = 1.0,
        VoidCallback? onComplete,
      }) async {
    try {
      // 🔇 기존 플레이어 정리
      if (_player != null) {
        await _fadeOut();
        await _player!.stop();
        await _player!.dispose();
      }

      // 🆕 새 플레이어 생성
      _player = AudioPlayer();

      _player!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          onComplete?.call();
        }
      });

      // 🧠 재생 준비 (에러 발생 시 잡힘)
      await _player!.setAudioSource(AudioSource.asset(assetPath));
      await _player!.setLoopMode(LoopMode.off);
      await _player!.setVolume(volume);
      await _player!.load(); // ✅ 꼭 분리해서 await

      print('🎧 재생 준비됨: $assetPath');

      await _player!.play(); // ✅ 준비된 후 play
      print("✅ play() 호출됨");
    } catch (e, stackTrace) {
      print('🎵 AudioManager play error: $e');
      print('📍 STACK: $stackTrace');
    }
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
  Future<void> dispose() async {
    print("🛑 AudioManager dispose 시작");
    try {
      if (_player != null) {
        await _fadeOut();
        await _player!.stop();
        await _player!.dispose();
        print("🌊 기존 AudioPlayer 정리 완료");
      }
    } catch (e, stackTrace) {
      print("🔴 AudioManager dispose error: $e");
      print("📍 STACK: $stackTrace");
    } finally {
      _player = null;
      print("✅ AudioManager dispose 완료");
    }
  }
}

