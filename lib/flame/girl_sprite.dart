import 'package:flame/components.dart';
import 'package:flame/game.dart';

class GirlSprite extends SpriteComponent with HasGameRef {
  GirlSprite({required Vector2 position})
      : super(
    size: Vector2.all(128),
    position: position,
    priority: 1,
  );

  @override
  Future<void> onLoad() async {
    sprite = Sprite(
      gameRef.images.fromCache('girl_walk.png'),
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(64, 64),
    );

    print("✅ [TEST] GirlSprite loaded with static sprite → position: $position, size: $size");
  }
}
