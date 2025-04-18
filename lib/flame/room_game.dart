import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'girl_sprite.dart';
import 'jordy_sprite.dart';
import 'package:flutter/material.dart';

class RoomGame extends FlameGame {
  late GirlSprite girl;
  late JordySprite jordy;

  @override
  Color backgroundColor() => const Color(0xFF111111); // 진한 회색

  @override
  Future<void> onLoad() async {
    print("🧱 RoomGame size = $size");
    print("📱 canvasSize = $canvasSize");

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
    girl = GirlSprite(position: Vector2(100, 150));
    add(girl);

    // 죠르디
    jordy = JordySprite(position: Vector2(200, 150));
    add(jordy);
  }
}
