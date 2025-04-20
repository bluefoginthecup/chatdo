import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

enum _Phase { idleLeft, walkingRight, idleRight, walkingLeft }

class GirlSprite extends SpriteAnimationComponent with HasGameRef {
  late final SpriteAnimation idleLeftAnim;
  late final SpriteAnimation idleRightAnim;
  late final SpriteAnimation walkCycleAnim;
  late final SpriteSheet spriteSheet;

  _Phase _phase = _Phase.idleLeft;
  final double speed = 20;
  double idleTimer = 0.0, idleDuration = 0.5;
  bool _isFlipped = false;

  GirlSprite({required Vector2 position})
      : super(position: position, size: Vector2(128, 256));

  @override
  Future<void> onLoad() async {
    final img = gameRef.images.fromCache('girl_walk.png');
    spriteSheet = SpriteSheet(image: img, srcSize: Vector2(256, 512));

    // Idle animations
    idleLeftAnim = SpriteAnimation.spriteList(
      [spriteSheet.getSprite(0, 0)],
      stepTime: 1.0,
      loop: false,
    );
    idleRightAnim = SpriteAnimation.spriteList(
      [spriteSheet.getSprite(0, 1)],
      stepTime: 1.0,
      loop: false,
    );

    // Single walk cycle (ping-pong): 1→2→3→4→3→2
    walkCycleAnim = SpriteAnimation.spriteList(
      [
        spriteSheet.getSprite(0, 0), // frame 1
        spriteSheet.getSprite(1, 0), // frame 2
        spriteSheet.getSprite(2, 0), // frame 3
        spriteSheet.getSprite(3, 0), // frame 4
        spriteSheet.getSprite(2, 0), // frame 3
        spriteSheet.getSprite(1, 0), // frame 2
      ],
      stepTime: 0.45,
      loop: true,
    );

    // Initial state: idle left
    animation = idleLeftAnim;
    flipHorizontally();
    _isFlipped = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (_phase) {
      case _Phase.idleLeft:
        idleTimer += dt;
        if (idleTimer >= idleDuration) {
          idleTimer = 0;
          _transitionTo(walkCycleAnim, flipX: false);
          _phase = _Phase.walkingRight;
        }
        break;
      case _Phase.walkingRight:
        position.x += speed * dt;
        if (position.x + size.x >= gameRef.size.x) {
          position.x = gameRef.size.x - size.x;
          _transitionTo(idleRightAnim, flipX: false);
          _phase = _Phase.idleRight;
        }
        break;
      case _Phase.idleRight:
        idleTimer += dt;
        if (idleTimer >= idleDuration) {
          idleTimer = 0;
          _transitionTo(walkCycleAnim, flipX: true);
          _phase = _Phase.walkingLeft;
        }
        break;
      case _Phase.walkingLeft:
        position.x -= speed * dt;
        if (position.x <= 0) {
          position.x = 0;
          _transitionTo(idleLeftAnim, flipX: true);
          _phase = _Phase.idleLeft;
        }
        break;
    }
  }

  /// Fade out → switch animation → fade in
  void _transitionTo(SpriteAnimation newAnim, {required bool flipX}) {
    // Remove existing effects
    children.whereType<Effect>().forEach((e) => e.removeFromParent());

    final fadeOut = OpacityEffect.to(
      0.2,
      EffectController(duration: 0.2, curve: Curves.easeInOut),
    );
    final switchEffect = FunctionEffect<GirlSprite>(
          (target, _) {
        target.animation = newAnim;
        if (flipX != target._isFlipped) {
          target.flipHorizontally();
          target._isFlipped = flipX;
        }
      },
      EffectController(duration: 0),
    );
    final fadeIn = OpacityEffect.to(
      1.0,
      EffectController(duration: 0.2, curve: Curves.easeInOut),
    );

    add(SequenceEffect([fadeOut, switchEffect, fadeIn]));
  }
}
