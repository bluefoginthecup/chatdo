import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:chatdo/game/room/day_event.dart';
import 'package:chatdo/game/room/girl_sprite.dart';
import 'package:chatdo/game/room/jordy_sprite.dart';
import 'package:chatdo/chatdo/providers/audio_manager.dart';
import '/game/components/speech_bubble_component.dart';
import 'package:chatdo/game/core/weather_scene_controller.dart';
import 'package:chatdo/chatdo/services/weather_service.dart';
import 'package:chatdo/game/room/dialogue_helper.dart';
import 'package:chatdo/chatdo/data/weather_repository.dart';



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
    print('📱 RoomScene created!');
    print('🎮 RoomScene loaded with event = ${event.backgroundImage}');

    _shuffleBgmQueue();

    AudioManager.instance.fadeOutAndPlay(
      'assets/sounds/vilage_theme.m4a',
      volume: 0.008,
      onComplete: _playNextRandomBgm,
    );

    final now = DateTime.now();
    final isMorningWeatherTime = now.hour >= 5 && now.hour < 12;

    final weatherRepo = WeatherRepository();
    final (text, _) = await weatherRepo.getTodayWeather(); // 실제 호출은 딱 1번
    final weatherDescription = weatherRepo.cachedDescription ?? 'clear';

    final weatherController = WeatherSceneController();

    if (isMorningWeatherTime) {
      final (text, farmBgPath) =
      await weatherController.getWeatherDialogueAndBg(weatherDescription);
      background = SpriteComponent(
        sprite: await gameRef.loadSprite(farmBgPath),
        size: gameRef.size,
        position: Vector2.zero(),
        priority: -1,
      );
      add(background);

      final jordy = JordySprite(
        position: Vector2(220, 400),
        dialogueList: [],
        spriteImage: event.jordy.spriteImage,
        animationName: event.jordy.animationName,
      )..priority = 1;
      add(jordy);



      bubble = SpeechBubbleComponent.createFor(jordy, []);
      jordy.speechBubble = bubble;
      add(bubble);

      final dialogues = await WeatherService().getDialoguesFromJson();
      showDialoguesSequentially(dialogues, bubble.show);
    } else {
      print('⛅ non-morning branch 진입');
      final indoorBgPath = await weatherController.getIndoorBackground(weatherDescription);

      background = SpriteComponent(
        sprite: await gameRef.loadSprite(indoorBgPath),
        size: gameRef.size,
        position: Vector2.zero(),
        priority: -1,
      );
      add(background);

      final jordy = JordySprite(
        position: Vector2(100, 400),
        dialogueList: event.jordy.dialogueList,
        spriteImage: event.jordy.spriteImage,
        animationName: event.jordy.animationName,
      )..priority = 1;
      add(jordy);

      final girl = GirlSprite(
        position: Vector2(100, 400),
        animationName: event.girl.animationName,
      )..priority = 1;
      add(girl);
      print('🎞️ Girl animation name: ${event.girl.animationName}');



      bubble = SpeechBubbleComponent.createFor(jordy, event.jordy.dialogueList);
      jordy.speechBubble = bubble;
      add(bubble);

      bubble.updateText(event.jordy.dialogueList.isNotEmpty
          ? event.jordy.dialogueList.first
          : '좋은 하루 되세요!');
    }
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
  @override
  void onRemove() {
    AudioManager.instance.dispose();
    super.onRemove();
  }
}
