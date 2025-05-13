// game/scenes/workout_scene.dart

import 'package:chatdo/game/overlay/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/overlay/story/dialogue_workout.dart';

class WorkoutScene extends DialogueSceneBase {
  WorkoutScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueWorkout;

  @override
  String get bgmPath => 'assets/sounds/town_theme.m4a'; // 기쁜 음악

  @override
  String get characterImagePath => 'jordy_happy.png'; // 기뻐하는 조르디 이미지
}
