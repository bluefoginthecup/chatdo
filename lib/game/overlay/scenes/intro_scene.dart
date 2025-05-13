import 'package:chatdo/game/overlay/scenes/dialogue_scene_base.dart';
import 'package:chatdo/game/overlay/story/dialogue_chapter0.dart';
class IntroScene extends DialogueSceneBase {
  IntroScene({super.onCompleted});




  @override
  List<Map<String, String>> get dialogueData => dialogueChapter0;

  @override
  String get bgmPath => 'assets/sounds/intro_theme.m4a';
  @override
  String get characterImagePath => 'jordy_closeup.png';


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print("🚀 IntroScene onLoad 진입");
  }
}
