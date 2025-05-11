import 'package:chatdo/game/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/story/dialogue_mon_am.dart';

class MonAmScene extends DialogueSceneBase {
  MonAmScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueMonAm;

  @override
  String get bgmPath => 'assets/sounds/mon_theme.m4a';

  @override
  String get characterImagePath => 'jordy_suggest.png';
}
