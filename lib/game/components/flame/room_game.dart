
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import '../../scenes/intro_scene.dart';
import 'girl_sprite.dart';
import 'jordy_sprite.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class RoomGame extends FlameGame with HasCollisionDetection {
  late GirlSprite girl;
  late JordySprite jordy;

  @override
  Color backgroundColor() => const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_closeup.png',
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

    final prefs = await SharedPreferences.getInstance();
    final introIndex = prefs.getInt('intro_dialogue_index') ?? 0;
    if (introIndex < 9999) {
      add(IntroScene());
    }
  }
}
