// room_game.dart (씬 조건 동적 분기 적용)

import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/scene_selector.dart';
import 'package:chatdo/game/core/scene_conditions.dart';
import '/game/scenes/room_scene.dart';

class RoomGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_shocked.png',
    ]);

    final prefs = await SharedPreferences.getInstance();
    const bool resetIntro = true;
    if (resetIntro) await prefs.remove('has_seen_intro'); // ✅ 바뀐 키 사용

    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

    if (!hasSeenIntro) {
      final showSick = await SceneConditions.shouldShowSickScene();
      add(SceneSelector(showSick: showSick));
    } else {
      add(RoomScene());
    }
  }
}
