// room_scene.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '/game/components/flame/girl_sprite.dart';
import '/game/components/flame/jordy_sprite.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';

class RoomScene extends Component with HasGameRef<FlameGame> {
  @override
  Future<void> onLoad() async {
    print('🎮 RoomScene loaded');
    AudioManager.instance.fadeOutAndPlay('assets/sounds/vilage_theme.m4a', volume: 0.02); // ✅ 여기서 항상 음악 재생

    // 🖼️ 배경 추가
    add(
      SpriteComponent(
        sprite: await gameRef.loadSprite('background.png'),
        size: gameRef.size,
        position: Vector2.zero(),
        priority: -1, // 배경은 맨 뒤
      ),
    );print('🎮 background loaded');
    final girl = GirlSprite(position: Vector2(100, 400))..priority = 2;
    final jordy = JordySprite(position: Vector2(250, 400))..priority = 1;


    // 👧 아가씨 추가
    add(girl);
    print('🎮 girl added');
    // 🧑 조르디 추가
    add(jordy);
    print('🎮 jordy added');
  }
}
