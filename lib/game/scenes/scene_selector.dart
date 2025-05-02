// scene_selector.dart

import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/game/components/flame/room_game.dart';
import '/game/scenes/intro_scene.dart';
import '/game/scenes/sick_scene.dart';
import '/game/scenes/room_scene.dart'; // ✅ 방 씬

class SceneSelector extends Component with HasGameReference<RoomGame> {
  final bool showSick;

  SceneSelector({required this.showSick});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 SceneSelector onLoad 진입");

    if (showSick) {
      print("🚀 SickScene 추가 시도");
      game.add(SickScene(
        onCompleted: () {
          print("✅ SickScene 완료 → RoomScene으로");
          game.add(RoomScene());
        },
      ));
    } else {
      print("🚀 IntroScene 추가 시도");
      game.add(IntroScene(
        onCompleted: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_intro', true);
          game.add(RoomScene());
        },
      ));
    }
  }
}
