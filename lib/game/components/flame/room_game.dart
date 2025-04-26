// room_game.dart (씬 조건 동적 분기 적용)

import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/scene_selector.dart';
import 'package:chatdo/game/core/scene_conditions.dart';

class RoomGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final prefs = await SharedPreferences.getInstance();
    const bool resetIntro = true;
    if (resetIntro) await prefs.remove('intro_dialogue_index');
    final introIndex = prefs.getInt('intro_dialogue_index') ?? 0;

    if (introIndex < 9999) {
      final showSick = await SceneConditions.shouldShowSickScene();
      add(SceneSelector(showSick: showSick));
    }
  }
}
