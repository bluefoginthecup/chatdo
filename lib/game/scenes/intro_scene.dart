import 'package:chatdo/game/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/story/dialogue_chapter0.dart';
class IntroScene extends DialogueSceneBase {
  IntroScene({super.onCompleted});


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 IntroScene onLoad 진입");

  }


  @override
  List<Map<String, String>> get dialogueData => dialogueChapter0;

  @override
  String get bgmPath => 'assets/sounds/intro_theme.m4a';
  @override
  String get characterImagePath => 'jordy_closeup.png';

}
