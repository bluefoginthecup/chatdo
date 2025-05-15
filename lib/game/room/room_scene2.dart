import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:chatdo/game/room/day_event.dart';
import 'package:chatdo/game/room/girl_sprite.dart';
import 'package:chatdo/game/room/jordy_sprite.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';
import '/game/components/speech_bubble_component.dart';
import 'package:chatdo/game/core/weather_scene_controller.dart'; // 추가


class RoomScene extends Component with HasGameRef<FlameGame> {
  final DayEvent event;

  RoomScene({required this.event});

  final List<String> bgmList = [
    'assets/sounds/senti_theme.m4a',
    'assets/sounds/apple_cider.m4a',
    'assets/sounds/deliciously_sour.m4a',
  ];

  late List<String> _bgmQueue;

  // ✅ 배경과 말풍선 컴포넌트를 추적
  late SpriteComponent background;
  late SpeechBubbleComponent bubble;

  @override
  Future<void> onLoad() async {
    print('🎮 RoomScene loaded with event = ${event.backgroundImage}');
    _shuffleBgmQueue();

    AudioManager.instance.fadeOutAndPlay(
      'assets/sounds/vilage_theme.m4a',
      volume: 0.008,
      onComplete: _playNextRandomBgm,
    );

    // ✅ 배경 스프라이트 로딩 및 저장
    print('🖼️ 배경 이미지 로딩 시도: ${event.backgroundImage}');
    final bgSprite = await gameRef.loadSprite(event.backgroundImage);
    background = SpriteComponent(
      sprite: bgSprite,
      size: gameRef.size,
      position: Vector2.zero(),
      priority: -1,
    );
    add(background);

    print('👧 Girl: pos=${event.girl.position}, anim=${event.girl.animationName}');
    add(GirlSprite(
      position: event.girl.position,
      animationName: event.girl.animationName,
    )..priority = 2);

    print('🐥 Jordy: sprite=${event.jordy.spriteImage}, pos=${event.jordy.position}, dialogue="${event.jordy.dialogueList}"');
    final jordy = JordySprite(
      position: event.jordy.position,
      dialogueList: event.jordy.dialogueList,
      spriteImage: event.jordy.spriteImage,
      animationName: event.jordy.animationName,
    )..priority = 1;
    add(jordy);

    // ✅ 말풍선 생성 및 저장
    bubble = SpeechBubbleComponent.createFor(jordy, event.jordy.dialogueList);
    jordy.speechBubble = bubble;
    add(bubble);

    // ✅ 날씨 컨트롤러로 배경 & 말풍선 텍스트 반영
    final weatherController = WeatherSceneController();
    await weatherController.applyWeatherToRoom(
      backgroundComponent: background,
      speechBubble: bubble,
    );
  }

  void _shuffleBgmQueue() {
    final random = Random();
    _bgmQueue = List<String>.from(bgmList)..shuffle(random);
    print('🎵 새로운 BGM 큐: $_bgmQueue');
  }

  void _playNextRandomBgm() {
    if (_bgmQueue.isEmpty) _shuffleBgmQueue();
    final nextBgm = _bgmQueue.removeAt(0);
    print('🎵 다음 곡 재생: $nextBgm');
    AudioManager.instance.fadeOutAndPlay(
      nextBgm,
      volume: 0.02,
      onComplete: _playNextRandomBgm,
    );
  }
}
