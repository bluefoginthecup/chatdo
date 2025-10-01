// dialogue_scene_base.dart (디버그 로그 포함)

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:chatdo/shared/providers/audio_manager.dart';

abstract class DialogueSceneBase extends PositionComponent
    with TapCallbacks, HasGameRef {
  List<Map<String, String>> get dialogueData;
  String get bgmPath;
  String get characterImagePath;
  final void Function()? onCompleted;

  DialogueSceneBase({this.onCompleted});

  int _dialogueIndex = 0;
  late final RectangleComponent _overlayDim;
  late final SpriteComponent _jordyCloseup;
  late final SpriteComponent _textBackground;
  late final TextComponent _speakerName;
  late final TextBoxComponent _textBox;
  late final TimerComponent _autoAdvanceTimer;
  late final TextComponent _prevButton;
  late final TextComponent _nextButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🟢 DialogueSceneBase.onLoad 시작");
    print("🧩 dialogueData 길이: ${dialogueData.length}");
    print("🧩 첫 줄: ${dialogueData[0]["line"]}");

    size = gameRef.size;
    position = Vector2.zero();
    print("📐 사이즈 설정됨: $size");

    await AudioManager.instance.stop();
    AudioManager.instance.play(bgmPath, volume: 0.1);
    print("🎧 음악 재생 시작: $bgmPath");

    _overlayDim = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xCC000000),
      priority: -1,
    );
    print("🟫 overlayDim 준비 완료");

    _jordyCloseup = SpriteComponent()
      ..sprite = await gameRef.loadSprite(characterImagePath)
      ..size = Vector2(200, 200)
      ..position = Vector2(size.x / 2 - 170, 360)
      ..opacity = 0.0;
    print("🧍 jordyCloseup 준비 완료");

    _textBackground = SpriteComponent()
      ..sprite = await gameRef.loadSprite('text_bg.png')
      ..size = Vector2(375, 160)
      ..position = Vector2(0, size.y - 180);
    print("📝 텍스트 배경 준비 완료");

    _speakerName = TextComponent(
      text: dialogueData[_dialogueIndex]["speaker"] ?? "",
      position: Vector2(40, size.y - 160),
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 16, color: Colors.red)),
    );
    print("🗣️ 화자 이름 준비 완료: ${_speakerName.text}");

    _textBox = TextBoxComponent(
      text: dialogueData[_dialogueIndex]["line"] ?? "",
      position: Vector2(40, size.y - 120),
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 20, color: Colors.black)),
      boxConfig: TextBoxConfig(
        maxWidth: 300,
        timePerChar: 0.0,
        growingBox: true,
      ),
    );
    print("💬 첫 대사 준비 완료: ${_textBox.text}");

    _prevButton = TextComponent(
      text: "<",
      position: Vector2(30, size.y + 0),
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 28, color: Colors.black)),
      priority: 1,
    );

    _nextButton = TextComponent(
      text: ">",
      position: Vector2(size.x - 50, size.y + 0),
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 28, color: Colors.black)),
      priority: 1,
    );

    _autoAdvanceTimer = TimerComponent(
      period: 4,
      repeat: true,
      onTick: _nextDialogue,
    );

    addAll([
      _overlayDim,
      _jordyCloseup,
      _textBackground,
      _speakerName,
      _textBox,
      _prevButton,
      _nextButton,
      _autoAdvanceTimer,
    ]);
    print("✅ 모든 컴포넌트 addAll 완료");

    _updateCharacterVisuals();
    print("🎬 대사 씬 초기화 완료");

    _isLoaded = true;
  }

  bool _hasCompleted = false;
  bool _isLoaded = false;

  void _updateDialogueText() {
    if (!_isLoaded) return;
    _textBox.text = dialogueData[_dialogueIndex]["line"] ?? "";
    _speakerName.text = dialogueData[_dialogueIndex]["speaker"] ?? "";
    _updateCharacterVisuals();
  }

  void _nextDialogue() {
    _dialogueIndex++;
    if (_dialogueIndex >= dialogueData.length) {
      if (!_hasCompleted) {
        _hasCompleted = true;
        onCompleted?.call();
        removeFromParent();
      }
      return;
    }
    _updateDialogueText();
  }

  void _previousDialogue() {
    if (_dialogueIndex > 0) {
      _dialogueIndex--;
      _updateDialogueText();
    }
  }

  void _updateCharacterVisuals() {
    final speaker = dialogueData[_dialogueIndex]["speaker"];
    _jordyCloseup.opacity = speaker == "조르디" ? 1.0 : 0.0;
  }

  @override
  void onRemove() {
    print("🛑 DialogueSceneBase.onRemove 호출됨");
    AudioManager.instance.stop(); // ✅ 씬 제거 시 오디오 정리
    super.onRemove(); // 반드시 호출
  }

  @override
  void onTapDown(TapDownEvent event) {
    final x = event.canvasPosition.x;
    final screenWidth = gameRef.size.x;
    if (x < screenWidth / 2) {
      _previousDialogue();
    } else {
      _nextDialogue();
    }
  }
}
