import 'package:chatdo/game/overlay/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/overlay/story/dialogue_mon_noon.dart';

class MonNoonScene extends DialogueSceneBase {
  MonNoonScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueMonNoon;

  @override
  String get bgmPath => 'assets/sounds/mon_theme.m4a';

  @override
  String get characterImagePath => 'jordy_cocoa.png';
}
