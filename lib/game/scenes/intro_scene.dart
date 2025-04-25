// game/scenes/intro_scene.dart

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../story/dialogue_chapter0.dart';
import 'package:provider/provider.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';



class IntroScene extends PositionComponent with TapCallbacks, HasGameRef<FlameGame> {

  IntroScene();
  int _dialogueIndex = 0;
  late TextBoxComponent _textBox;
  late TextComponent _speakerName;
  late RectangleComponent _textBackground;
  late RectangleComponent _overlayDim;
  late TimerComponent _blinkTimer;
  late TimerComponent _autoAdvanceTimer;
  late SpriteComponent _jordyCloseup;
  bool _hintVisible = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();


    size = gameRef.size;
    position = Vector2.zero();

    final prefs = await SharedPreferences.getInstance();
    _dialogueIndex = prefs.getInt('intro_dialogue_index') ?? 0;

    _overlayDim = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x88000000),
      priority: 90,
    );

    final textBoxWidth = gameRef.size.x - 10;
    final textBoxHeight = 100.0;
    final textBoxPosition = Vector2(5, gameRef.size.y - textBoxHeight - 60);

    final current = dialogueChapter0[_dialogueIndex];

    _speakerName = TextComponent(
      text: current["speaker"]!,
      position: textBoxPosition + Vector2(10, -24),
      anchor: Anchor.topLeft,
      priority: 101,
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 20),
      ),
    );

    _textBackground = RectangleComponent(
      position: textBoxPosition,
      size: Vector2(textBoxWidth, textBoxHeight),
      paint: Paint()..color = const Color(0xAA000000),
      priority: 99,
    );

    _textBox = TextBoxComponent(
      text: current["line"]!,
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
      position: Vector2((gameRef.size.x - 400) / 2, gameRef.size.y - 450),
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
      _speakerName,
      _textBox,
      _blinkTimer,
    ]);

    add(_autoAdvanceTimer);
    _updateCharacterVisuals();

    await Future.delayed(Duration(milliseconds: 300));
    AudioManager.instance.play('assets/sounds/intro_theme.m4a', volume: 0.1);
  }

  void _nextDialogue() async {
    if (_dialogueIndex < dialogueChapter0.length - 1) {
      _dialogueIndex++;
      final current = dialogueChapter0[_dialogueIndex];
      _speakerName.text = current["speaker"]!;
      _textBox.text = current["line"]!;
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('intro_dialogue_index', _dialogueIndex);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('intro_dialogue_index', 9999); // 끝났음을 의미
      removeFromParent();
      return;
    }
    _updateCharacterVisuals();
  }

  void _previousDialogue() async {
    if (_dialogueIndex > 0) {
      _dialogueIndex--;
      final current = dialogueChapter0[_dialogueIndex];
      _speakerName.text = current["speaker"]!;
      _textBox.text = current["line"]!;
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('intro_dialogue_index', _dialogueIndex);
      _updateCharacterVisuals();
    }
  }

  void _updateCharacterVisuals() {
    final speaker = dialogueChapter0[_dialogueIndex]["speaker"];
    _jordyCloseup.opacity = speaker == "조르디" ? 1.0 : 0.0;
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
