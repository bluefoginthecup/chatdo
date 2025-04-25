// scene_selector.dart

import 'package:flame/components.dart';
import '/game/components/flame/room_game.dart';
import '/game/scenes/intro_scene.dart';
import '/game/scenes/sick_scene.dart';

class SceneSelector extends Component with HasGameReference<RoomGame> {
  final bool showSick;

  SceneSelector({required this.showSick});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 SceneSelector onLoad 진입");

    if (showSick) {
      print("🚀 SickScene 추가 시도");
      game.add(SickScene());
    } else {
      print("🚀 IntroScene 추가 시도");
      game.add(IntroScene(
        onCompleted: () => game.add(SickScene()),
      ));
    }
  }
}