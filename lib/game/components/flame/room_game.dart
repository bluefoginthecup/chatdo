import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/scene_selector.dart';
import '/game/scene_conditions/sick_scene_condition.dart';
import '/game/scene_conditions/workout_scene_condition.dart';
import '/game/scenes/room_scene.dart';
import 'package:chatdo/game/events/scene_event_manager.dart';

class RoomGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_shocked.png',
      'jordy_happy.png', // 🎉 workout scene용 추가해두면 좋아요
    ]);

    final prefs = await SharedPreferences.getInstance();
    const bool resetIntro = true;
    if (resetIntro) await prefs.remove('has_seen_intro');

    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

    if (!hasSeenIntro) {
      final showSick = await SickSceneCondition.shouldShow(); // ✅ 수정됨
      final showWorkout = await WorkoutSceneCondition.shouldShow(); // ✅ 추가됨

      add(SceneSelector(
        showSick: showSick,
        showWorkoutCongrats: showWorkout,
      ));
    } else {
      final sceneShown = await SceneEventManager(
        onShowScene: (scene) {
          add(scene);
        },
      ).checkTimeBasedScenes();

      if (!sceneShown) {
        add(RoomScene());
      }
    }
  }
}