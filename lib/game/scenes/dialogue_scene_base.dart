// dialogue_scene_base.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';

abstract class DialogueSceneBase extends PositionComponent with TapCallbacks, HasGameRef {
  List<Map<String, String>> get dialogueData;
  String get bgmPath;
  final void Function()? onCompleted;

  DialogueSceneBase({this.onCompleted});

  int _dialogueIndex = 0;
  late final TextComponent _textBox;
  late final TextComponent _speakerName;
  late final SpriteComponent _jordyCloseup;
  late final TimerComponent _dialogueTimer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await AudioManager.instance.stop();
    AudioManager.instance.play(bgmPath, volume: 0.1);

    _textBox = TextComponent(
      text: dialogueData[_dialogueIndex]["line"] ?? "",
      position: Vector2(30, 360),
      size: Vector2(300, 200),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 20)),
    );

    _speakerName = TextComponent(
      text: dialogueData[_dialogueIndex]["speaker"] ?? "",
      position: Vector2(30, 320),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16)),
    );

    _jordyCloseup = SpriteComponent()
      ..sprite = await gameRef.loadSprite('jordy_closeup.png')
      ..size = Vector2(128, 128)
      ..position = Vector2(180, 180)
      ..opacity = 0.0;

    _updateCharacterVisuals();

    _dialogueTimer = TimerComponent(period: 4, repeat: true, onTick: _nextDialogue);

    addAll([_textBox, _speakerName, _jordyCloseup, _dialogueTimer]);
  }

  void _nextDialogue() {
    _dialogueIndex++;
    if (_dialogueIndex >= dialogueData.length) {
      onCompleted?.call();
      removeFromParent();
      return;
    }

    _textBox.text = dialogueData[_dialogueIndex]["line"] ?? "";
    _speakerName.text = dialogueData[_dialogueIndex]["speaker"] ?? "";
    _updateCharacterVisuals();
  }

  void _previousDialogue() {
    if (_dialogueIndex > 0) {
      _dialogueIndex--;
      _textBox.text = dialogueData[_dialogueIndex]["line"] ?? "";
      _speakerName.text = dialogueData[_dialogueIndex]["speaker"] ?? "";
      _updateCharacterVisuals();
    }
  }

  void _updateCharacterVisuals() {
    final speaker = dialogueData[_dialogueIndex]["speaker"];
    _jordyCloseup.opacity = speaker == "조르디" ? 1.0 : 0.0;
  }

  @override
  void onTapDown(TapDownEvent event) => _nextDialogue();
}
