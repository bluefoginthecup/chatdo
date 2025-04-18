import 'package:flame/components.dart';
import 'package:flutter/material.dart';


class JordySprite extends SpriteComponent with HasGameRef {
  JordySprite({required Vector2 position})
      : super(
    size: Vector2.all(64),
    position: position,
  );

  late TextComponent speechBubble;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(gameRef.images.fromCache('jordy_idle.png'));

    speechBubble = TextComponent(
      text: '어서 오세요, 아가씨!',
      position: Vector2(position.x, position.y - 20),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.black87,
          fontSize: 12,
        ),
      ),
    );
    add(speechBubble);
  }
}
