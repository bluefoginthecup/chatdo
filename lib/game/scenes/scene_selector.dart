import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/intro_scene.dart';
import 'package:chatdo/game/scenes/sick_scene.dart';
import 'package:chatdo/game/scenes/room_scene.dart';
import 'package:chatdo/game/scenes/workout_scene.dart';
import 'package:chatdo/game/components/flame/room_game.dart';
import 'package:flutter/foundation.dart';

class SceneSelector extends Component with HasGameRef<RoomGame> {
  final bool showSick;
  final bool showWorkoutCongrats;
  VoidCallback? onCompleted;

  SceneSelector({
    required this.showSick,
    required this.showWorkoutCongrats,
    this.onCompleted,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 SceneSelector onLoad 진입");

    if (showSick) {
      print("🚀 SickScene 추가 시도");
      gameRef.add(SickScene(
        onCompleted: () {
          print("✅ SickScene 완료");
          onCompleted?.call();
        },
      ));
    } else if (showWorkoutCongrats) {
      print("🎉 WorkoutScene 추가 시도");
      gameRef.add(WorkoutScene(
        onCompleted: () {
          print("✅ WorkoutScene 완료");
          onCompleted?.call();
        },
      ));
    } else {
      print("🚀 IntroScene 추가 시도");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_intro', true);
      onCompleted?.call();
    }
  }
}
