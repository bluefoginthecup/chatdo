import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/intro_scene.dart';
import 'package:chatdo/game/scenes/sick_scene.dart';
import 'package:chatdo/game/scenes/room_scene.dart';
import 'package:chatdo/game/scenes/workout_scene.dart';
import 'package:chatdo/game/components/flame/room_game.dart';
// Game 타입 제대로 지정
// Flame 1.8+ 기준

class SceneSelector extends Component with HasGameRef<RoomGame> {
  final bool showSick;
  final bool showWorkoutCongrats;

  SceneSelector({
    required this.showSick,
    required this.showWorkoutCongrats,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 SceneSelector onLoad 진입");

    if (showSick) {
      print("🚀 SickScene 추가 시도");
      gameRef.add(SickScene(
        onCompleted: () {
          print("✅ SickScene 완료 → RoomScene으로");
          gameRef.add(RoomScene());
        },
      ));
    } else if (showWorkoutCongrats) {
      print("🎉 WorkoutScene 추가 시도");
      gameRef.add(WorkoutScene(
        onCompleted: () {
          print("✅ WorkoutScene 완료 → RoomScene으로");
          gameRef.add(RoomScene());
        },
      ));
    } else {
      print("🚀 IntroScene 추가 시도");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_intro', true);
      gameRef.add(RoomScene());
    }
  }
}
