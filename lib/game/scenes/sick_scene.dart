import 'package:chatdo/game/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/story/dialogue_sick.dart';

class SickScene extends DialogueSceneBase {
  SickScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueSick;

  @override
  String get bgmPath => 'assets/sounds/sick_theme.mp3';

  @override
  String get characterImagePath => 'jordy_shocked.png'; // 아픈 조르디 그림

}
