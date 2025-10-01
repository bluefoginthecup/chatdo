import 'package:chatdo/features/game/overlay/scenes/dialogue_scene_base.dart';

class SatNightScene extends DialogueSceneBase {
  SatNightScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => [
        {'character': 'Jordy', 'text': '오늘은 토요일 밤이야. 느긋하게 쉬자! 🍷'},
      ];

  @override
  String get bgmPath => 'assets/sounds/chill_saturday.mp3';

  @override
  String get characterImagePath => 'jordy_casual.png'; // 필요하면 대체 이미지
}
