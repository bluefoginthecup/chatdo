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
  late TextComponent _nextHint;
  late TextComponent _prevHint;
  late TimerComponent _blinkTimer;
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

    _nextHint = TextComponent(
      text: '▶︎',
      position: textBoxPosition + Vector2(textBoxWidth - 32, textBoxHeight - 24),
      anchor: Anchor.topLeft,
      priority: 101,
      textRenderer: TextPaint(style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16)),
    );

    _prevHint = TextComponent(
      text: '◀︎',
      position: textBoxPosition + Vector2(8, textBoxHeight - 24),
      anchor: Anchor.topLeft,
      priority: 101,
      textRenderer: TextPaint(style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16)),
    );

    _blinkTimer = TimerComponent(
      period: 0.6,
      repeat: true,
      onTick: () {
        _hintVisible = !_hintVisible;
        _nextHint.text = _hintVisible ? '▶︎' : '';
        _prevHint.text = _hintVisible ? '◀︎' : '';
      },
    );

    final jordySprite = await gameRef.loadSprite('jordy_closeup.png');
    _jordyCloseup = SpriteComponent(
      sprite: jordySprite,
      size: Vector2(320, 320),
      position: Vector2((gameRef.size.x - 320) / 2, gameRef.size.y - 360),
      priority: 95,
      // 'visible' 속성이 없으므로 대신 isHud 또는 opacity 활용 예정
    );

    addAll([
      _overlayDim,
      _jordyCloseup,
      _textBackground,
      _textBox,
      _nextHint,
      _prevHint,
      _blinkTimer
    ]);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPos = event.localPosition;
    if (_nextHint.containsPoint(tapPos)) {
      if (_dialogueIndex < dialogueChapter0.length - 1) {
        _dialogueIndex++;
        _textBox.text = dialogueChapter0[_dialogueIndex];
      } else {
        removeFromParent();
      }
    } else if (_prevHint.containsPoint(tapPos)) {
      if (_dialogueIndex > 0) {
        _dialogueIndex--;
        _textBox.text = dialogueChapter0[_dialogueIndex];
      }
    }

    // 조르디 클로즈업 표시 여부
    _jordyCloseup.opacity = (_dialogueIndex == 0 || _dialogueIndex == 2 || _dialogueIndex == 3) ? 1.0 : 0.0;
  }
}
