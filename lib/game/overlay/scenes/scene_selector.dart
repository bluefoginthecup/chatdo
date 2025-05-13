import 'package:flame/components.dart';
import 'package:chatdo/game/components/flame/room_game.dart';
import 'package:chatdo/game/overlay/events/scene_event_manager.dart';
import 'package:flutter/foundation.dart';

class SceneSelector extends Component with HasGameRef<RoomGame> {
  VoidCallback? onCompleted;

  SceneSelector({this.onCompleted});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 SceneSelector onLoad 진입");

    await gameRef.sceneEventManager.checkTimeBasedScenes();
    onCompleted?.call();
  }
}
