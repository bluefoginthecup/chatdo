import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/scene_selector.dart';
import '/game/scene_conditions/sick_scene_condition.dart';
import '/game/scene_conditions/workout_scene_condition.dart';
import '/game/scenes/room_scene.dart';
import 'package:chatdo/game/events/scene_event_manager.dart';
import 'package:flutter/foundation.dart';


class RoomGame extends FlameGame {
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

    final prefs = await SharedPreferences.getInstance();
    const bool resetIntro = true;
    if (resetIntro) await prefs.remove('has_seen_intro');
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

    final sceneBuilders = <void Function(VoidCallback)>[];

    if (!hasSeenIntro) {
      final showSick = await SickSceneCondition.shouldShow();
      final showWorkout = await WorkoutSceneCondition.shouldShow();
      sceneBuilders.add((onCompleted) => add(SceneSelector(
        showSick: showSick,
        showWorkoutCongrats: showWorkout,
        onCompleted: onCompleted,
      )));
    }

    final eventScenes = await SceneEventManager(
      onShowScene: (scene) => add(scene),
    ).gatherScenesToShow();

    sceneBuilders.addAll(eventScenes);

    if (sceneBuilders.isNotEmpty) {
      _playScenesSequentially(sceneBuilders);
    } else {
      add(RoomScene());
    }
  }

  void _playScenesSequentially(List<void Function(VoidCallback)> builders, [int index = 0]) {
    if (index >= builders.length) {
      add(RoomScene());
      return;
    }

    final builder = builders[index];
    builder(() {
      _playScenesSequentially(builders, index + 1);
    });
  }
}
