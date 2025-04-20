
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import '../../scenes/intro_scene.dart';
import 'girl_sprite.dart';
import 'jordy_sprite.dart';
import 'dart:ui'; // ✅ Color를 위한 올바른 import

class RoomGame extends FlameGame with HasCollisionDetection {
  late GirlSprite girl;
  late JordySprite jordy;
  late IntroScene _introScene;

  @override
  Color backgroundColor() => const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    print("🧱 RoomGame size = \$size");
    print("📱 canvasSize = \$canvasSize");
    print("📐 gameRef.size: \$size");
    print("🔍 devicePixelRatio = \${window.devicePixelRatio}");

    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
    ]);

    // 방 배경
    final bg = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size
      ..priority = -1;
    add(bg);

    // 아가씨
    girl = GirlSprite(position: Vector2(0, 400));
    add(girl);

    // 죠르디
    jordy = JordySprite(position: Vector2(250, 400));
    add(jordy);

    // 인트로 대사
    _introScene = IntroScene();
    await add(_introScene);
  }
}
