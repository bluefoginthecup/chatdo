import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '/game/components/speech_bubble_component.dart';

class JordySprite extends SpriteComponent with HasGameRef {
  final List<String> dialogueList;
  final String spriteImage;
  final String? animationName;

  JordySprite({
    required Vector2 position,
    required this.dialogueList,
    required this.spriteImage,
    this.animationName,
  }) : super(
    size: Vector2.all(128),
    position: position,
  );

  SpeechBubbleComponent? speechBubble;
  final Random _random = Random();
  double _timeSinceLastChange = 0.0;
  final double dialogueChangeInterval = 5.0;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(gameRef.images.fromCache(spriteImage));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastChange += dt;

    if (_timeSinceLastChange >= dialogueChangeInterval && dialogueList.length > 1) {
      _timeSinceLastChange = 0;
      String newDialogue;
      do {
        newDialogue = dialogueList[_random.nextInt(dialogueList.length)];
      }while (newDialogue == speechBubble?.currentText);

      speechBubble?.updateText(newDialogue);
    }
  }
}