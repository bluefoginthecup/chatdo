import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/scene_selector.dart';
import '/game/scenes/room_scene.dart';
import 'package:chatdo/game/events/scene_event_manager.dart';
import 'package:flutter/foundation.dart';
class RoomGame extends FlameGame {
  late final SceneEventManager sceneEventManager;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_shocked.png',
      'jordy_happy.png',
    ]);

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
