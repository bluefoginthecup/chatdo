import 'package:chatdo/game/overlay/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/overlay/story/dialogue_tue_am.dart';

class TueAmScene extends DialogueSceneBase {
  TueAmScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueTueAm;

  @override
  String get bgmPath => 'assets/sounds/senti_theme.m4a';

  @override
  String get characterImagePath => 'jordy_fighting.png';
}
