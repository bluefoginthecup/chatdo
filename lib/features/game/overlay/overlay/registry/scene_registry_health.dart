import 'package:flutter/foundation.dart';
import 'package:chatdo/features/game/overlay/scenes/sick_scene.dart';
import 'package:chatdo/features/game/overlay/scene_conditions/sick_scene_condition.dart';
import 'package:chatdo/features/game/overlay/scenes/workout_scene.dart';
import 'package:chatdo/features/game/overlay/scene_conditions/workout_scene_condition.dart';

// 씬 생성자 타입: void Function(VoidCallback onCompleted)
typedef SceneBuilder = Object Function(VoidCallback onCompleted);

List<MapEntry<Future<bool> Function(), SceneBuilder>> buildHealthScenes() => [
      MapEntry(
        SickSceneCondition.shouldShow,
        (onCompleted) {
          print("🎯 SickScene builder 실행됨");
          return SickScene(onCompleted: onCompleted);
        },
      ),
      MapEntry(
        WorkoutSceneCondition.shouldShow,
        (onCompleted) {
          print("🎯 WorkoutScene builder 실행됨");
          return WorkoutScene(onCompleted: onCompleted);
        },
      ),
    ];
