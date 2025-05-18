import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

enum _Phase { idleLeft, walkingRight, idleRight, walkingLeft }

class GirlSprite extends SpriteAnimationComponent with HasGameRef {
  late final SpriteAnimation idleAnim;
  late final SpriteAnimation walkCycleAnim;
  late final SpriteSheet spriteSheet;

  _Phase? _phase;
  final double speed = 20;
  double idleTimer = 0.0, idleDuration = 0.5;

  bool _isFlipped = false;
  final String? animationName;


  GirlSprite({required Vector2 position, this.animationName})
      : super(
    position: position,
    size: Vector2(128, 256), // ✅ 여기!
  );

  @override
  Future<void> onLoad() async {
    final img = gameRef.images.fromCache('girl_walk.png');
    spriteSheet = SpriteSheet(image: img, srcSize: Vector2(256, 512));

    idleAnim = SpriteAnimation.spriteList(
      [spriteSheet.getSprite(0, 0)],
      stepTime: 1.0,
      loop: false,
    );

    walkCycleAnim = SpriteAnimation.spriteList(
      [
        spriteSheet.getSprite(0, 0),
        spriteSheet.getSprite(0, 1),
        spriteSheet.getSprite(0, 2),
        spriteSheet.getSprite(0, 3),
        spriteSheet.getSprite(0, 2),
        spriteSheet.getSprite(0, 1),
      ],
      stepTime: 0.2,
      loop: true,
    );

    // 기본 애니메이션 설정
    animation = (animationName == 'walkRight' || animationName == 'walkLeft')
        ? walkCycleAnim
        : idleAnim;

    Future.microtask(() {
      _phase = switch (animationName) {
        'walkRight' => _Phase.walkingRight,
        'walkLeft' => _Phase.walkingLeft,
        'idle' => _Phase.idleLeft,
        _ => _Phase.idleLeft,
      };


    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_phase == null) return;

    switch (_phase!) {
      case _Phase.idleLeft:
        idleTimer += dt;
        if (idleTimer >= idleDuration) {
          idleTimer = 0;
          position.x = 0;// ✅ 왼쪽 끝에서 시작
          _transitionTo(walkCycleAnim, flipX: false);
          _phase = _Phase.walkingRight;
        }
        break;
      case _Phase.walkingRight:
        position.x += speed * dt;
        if (position.x + size.x >= gameRef.size.x - 1) {
          position.x = gameRef.size.x - size.x;
          _transitionTo(idleAnim, flipX: false);
          _phase = _Phase.idleRight;
        }
        break;
      case _Phase.idleRight:
        idleTimer += dt;
        if (idleTimer >= idleDuration) {
          idleTimer = 0;
          position.x = gameRef.size.x - size.x; // ✅ 오른쪽 끝에서 시작
          _transitionTo(walkCycleAnim, flipX: true);
          _phase = _Phase.walkingLeft;
        }
        break;
      case _Phase.walkingLeft:
        position.x -= speed * dt;
        if (position.x <= 0) {
          position.x = 0;
          _transitionTo(idleAnim, flipX: true);
          _phase = _Phase.idleLeft;
        }
        break;
    }

    position.x = position.x.clamp(0, gameRef.size.x - size.x);
  }

  void _transitionTo(SpriteAnimation? newAnim, {required bool flipX}) {
    if (!isMounted || newAnim == null) {
      print("❌ transitionTo skipped: not mounted or newAnim is null");

      return;
    }

    children.whereType<Effect>().forEach((e) => e.removeFromParent());

    final fadeOut = OpacityEffect.to(0.2, EffectController(duration: 0.2));
    final switchEffect = FunctionEffect<GirlSprite>(
          (target, _) {
        target.animation = newAnim;
        if (flipX != _isFlipped) {
          target.flipHorizontally();
          _isFlipped = flipX;

        }      print('🎭 flipX: $flipX | isFlipped: $_isFlipped | position.x: ${position.x}');
        print('🎯 BEFORE flip: x=${position.x}');
        print('🎯 AFTER flip: x=${position.x}');

          },
      EffectController(duration: 0),
    );

    final fadeIn = OpacityEffect.to(1.0, EffectController(duration: 0.2));

    add(SequenceEffect([fadeOut, switchEffect, fadeIn]));
  }
}
