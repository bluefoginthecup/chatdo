import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/overlay/events/scene_event_manager.dart';
import 'package:chatdo/game/overlay/scenes/scene_selector.dart';
import 'package:flutter/foundation.dart';
class RoomGame extends FlameGame {
  late final SceneEventManager sceneEventManager;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    print('📦 preload images 시작');
    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_shocked.png',
      'jordy_happy.png',
      'sp_jordy_study.png',
      'background_studyroom.png',
    ]);
    print('✅ preload images 완료');

    sceneEventManager = SceneEventManager(
      onShowScene: (scene) async {
        print("🧩 onShowScene 호출됨 → 씬 추가 시도: ${scene.runtimeType}");
        await add(scene);
        print("🧩 씬 추가 완료: ${scene.runtimeType}");
      },
    );

    // ✅ 여기서 씬 조건 확인 및 Intro 포함 자동 처리
    await sceneEventManager.checkTimeBasedScenes();
  }
}
