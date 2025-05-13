import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:chatdo/game/room/day_event.dart';
import 'package:chatdo/game/room/girl_sprite.dart';
import 'package:chatdo/game/room/jordy_sprite.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';

class RoomScene extends Component with HasGameRef<FlameGame> {
  final DayEvent event;

  RoomScene({required this.event});

  final List<String> bgmList = [
    'assets/sounds/senti_theme.m4a',
    'assets/sounds/apple_cider.m4a',
    'assets/sounds/deliciously_sour.m4a',
  ];

  late List<String> _bgmQueue;

  @override
  Future<void> onLoad() async {
    print('🎮 RoomScene loaded with event = ${event.backgroundImage}');

    _shuffleBgmQueue();

    AudioManager.instance.fadeOutAndPlay(
      'assets/sounds/vilage_theme.m4a',
      volume: 0.008,
      onComplete: _playNextRandomBgm,
    );

    print('🖼️ 배경 이미지 로딩 시도: ${event.backgroundImage}');
    final bgSprite = await gameRef.loadSprite(event.backgroundImage);
    add(SpriteComponent(
      sprite: bgSprite,
      size: gameRef.size,
      position: Vector2.zero(),
      priority: -1,
    ));

    print('👧 Girl: pos=${event.girl.position}, anim=${event.girl.animationName}');
    add(GirlSprite(
      position: event.girl.position,
      animationName: event.girl.animationName,
    )..priority = 2);

    print('🐥 Jordy: sprite=${event.jordy.spriteImage}, pos=${event.jordy.position}, dialogue="${event.jordy.dialogueList}"');
    add(JordySprite(
      position: event.jordy.position,
      dialogueList: event.jordy.dialogueList,
      spriteImage: event.jordy.spriteImage,
      animationName: event.jordy.animationName,
    )..priority = 1);
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
