import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'dart:ui';

class GirlSprite extends SpriteAnimationComponent with HasGameRef{
  GirlSprite({required Vector2 position})
      : super(
    size: Vector2(128,256),
    position: position,
    priority: 1,
  );

  @override
  Future<void> onLoad() async {

    final image = gameRef.images.fromCache('girl_walk.png');

    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2(256, 512), // ✅ 각 프레임 크기!
    );

    animation = spriteSheet.createAnimation(
      row: 0,   // 윗줄 사용
      stepTime: 0.2,
      to: 4,    // 0,1,2,3 프레임만 사용
    );

    print("✅ GirlSprite 애니메이션 OK — 확대해서 보여주기!");

  }
  @override
  void render(Canvas canvas) {
    // ✅ sprite 그리기 전에 연한 초록색 박스 그리기
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0x5500FF00));
    super.render(canvas); // sprite 그리기
  }

}

