import 'package:chatdo/features/game/overlay/scenes/dialogue_scene_base.dart';
import 'package:chatdo/features/game/overlay/story/dialogue_sun_pm.dart';

class SunPmScene extends DialogueSceneBase {
  SunPmScene({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => dialogueSunPm;

  @override
  String get bgmPath => 'assets/sounds/soft_sunday.m4a';

  @override
  String get characterImagePath => 'jordy_study.png';
}
