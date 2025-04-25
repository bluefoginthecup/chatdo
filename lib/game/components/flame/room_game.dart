import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../scenes/intro_scene.dart';
import 'girl_sprite.dart';
import 'jordy_sprite.dart';
import '/game/scenes/sick_scene.dart';
import '/game/scenes/scene_selector.dart';

class RoomGame extends FlameGame with HasCollisionDetection {
  late GirlSprite girl;
  late JordySprite jordy;
  AudioPlayer? bgmPlayer;

  @override
  Color backgroundColor() => const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    // 🎵 배경음악 플레이어 생성 및 설정
    bgmPlayer = AudioPlayer();
    await bgmPlayer!.setLoopMode(LoopMode.one);

    // 🔽 필요한 이미지 미리 로드
    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_closeup.png',
    ]);

    // 방 배경
    final bg = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size
      ..priority = -1;
    add(bg);

    // 아가씨
    girl = GirlSprite(position: Vector2(0, 400));
    add(girl);

    // 죠르디
    jordy = JordySprite(position: Vector2(250, 400));
    add(jordy);

    // 🔽 인트로 다이얼로그 상태 초기화
    final prefs = await SharedPreferences.getInstance();
    const bool resetIntro = true; //출시 때는 false로
    if (resetIntro) await prefs.remove('intro_dialogue_index');
    final introIndex = prefs.getInt('intro_dialogue_index') ?? 0;


    // 🔽 인트로 씬 실행 (🎵 콜백으로 음악 요청 넘김)
    if (introIndex < 9999) {
      add(SceneSelector(showSick: false));
    }



    // 🎵 씬에서 호출하는 음악 재생 함수
    Future<void> playMusic(String assetPath) async {
      try {
        await bgmPlayer?.dispose();
        bgmPlayer = AudioPlayer();
        await bgmPlayer!.setAudioSource(AudioSource.asset(assetPath));
        await bgmPlayer!.setVolume(0.02);
        await bgmPlayer!.load(); // 음악 로드 명시적으로 호출
        await bgmPlayer!.play();

        print("🎵 음악 재생 성공: $assetPath");
      } catch (e, stackTrace) {
        print("🎵 음악 로드 실패: $e");
        print("📍 발생 위치:\n$stackTrace");
      }
    }


    @override
    Future<void> onDetach() async {
      try {
        if (bgmPlayer?.playing ?? false) {
          await bgmPlayer?.stop();
        }
        await bgmPlayer?.dispose();
      } catch (e) {
        print("🎵 음악 정리 중 에러: $e");
      }
      super.onDetach();
    }
  }
}