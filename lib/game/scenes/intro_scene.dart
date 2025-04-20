// game/scenes/intro_scene.dart

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../story/dialogue_chapter0.dart';

class IntroScene extends PositionComponent with TapCallbacks, HasGameRef<FlameGame> {
  int _dialogueIndex = 0;
  late TextBoxComponent _textBox;
  late RectangleComponent _textBackground;
  late RectangleComponent _overlayDim;
  late TimerComponent _blinkTimer;
  late TimerComponent _autoAdvanceTimer;
  late SpriteComponent _jordyCloseup;
  bool _hintVisible = true;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    position = Vector2.zero();

    _overlayDim = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x88000000),
      priority: 90,
    );

    final textBoxWidth = gameRef.size.x - 80;
    final textBoxHeight = 100.0;
    final textBoxPosition = Vector2(40, gameRef.size.y - textBoxHeight - 60);

    _textBackground = RectangleComponent(
      position: textBoxPosition,
      size: Vector2(textBoxWidth, textBoxHeight),
      paint: Paint()..color = const Color(0xAA000000),
      priority: 99,
    );

    _textBox = TextBoxComponent(
      text: dialogueChapter0[_dialogueIndex],
      boxConfig: TextBoxConfig(
        maxWidth: textBoxWidth - 32,
        timePerChar: 0.0,
        growingBox: true,
        margins: const EdgeInsets.all(16),
      ),
      position: textBoxPosition,
      anchor: Anchor.topLeft,
      priority: 100,
    );

    _blinkTimer = TimerComponent(
      period: 0.6,
      repeat: true,
      onTick: () {
        _hintVisible = !_hintVisible;
      },
    );

    final jordySprite = await gameRef.loadSprite('jordy_closeup.png');
    _jordyCloseup = SpriteComponent(
      sprite: jordySprite,
      size: Vector2(320, 320),
      position: Vector2((gameRef.size.x - 320) / 2, gameRef.size.y - 360),
      priority: 95,
    );

    _autoAdvanceTimer = TimerComponent(
      period: 4.0,
      repeat: true,
      onTick: _nextDialogue,
    );

    addAll([
      _overlayDim,
      _jordyCloseup,
      _textBackground,
      _textBox,
      _blinkTimer,
    ]);

    add(_autoAdvanceTimer);
    _updateCharacterVisuals();
  }

  void _nextDialogue() {
    if (_dialogueIndex < dialogueChapter0.length - 1) {
      _dialogueIndex++;
      _textBox.text = dialogueChapter0[_dialogueIndex];
    } else {
      removeFromParent();
      return;
    }
    _updateCharacterVisuals();
  }

  void _previousDialogue() {
    if (_dialogueIndex > 0) {
      _dialogueIndex--;
      _textBox.text = dialogueChapter0[_dialogueIndex];
      _updateCharacterVisuals();
    }
  }

  void _updateCharacterVisuals() {
    _jordyCloseup.opacity = (_dialogueIndex == 0 || _dialogueIndex == 2 || _dialogueIndex == 3) ? 1.0 : 0.0;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPos = event.localPosition;
    final boxLeft = _textBox.position.x;
    final boxRight = _textBox.position.x + _textBox.width;

    if (tapPos.x < (boxLeft + boxRight) / 2) {
      _previousDialogue();
    } else {
      _nextDialogue();
    }
  }
}
