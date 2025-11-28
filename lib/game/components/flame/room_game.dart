import 'package:flame/game.dart';
import 'package:chatdo/game/overlay/events/scene_event_manager.dart';
class RoomGame extends FlameGame {
  late final SceneEventManager sceneEventManager;
  bool _hasRunScenes = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    print('📦 preload images 시작');
    await images.loadAll([
      'background.png',
      'girl_walk.png',
      'jordy_idle.png',
      'jordy_shocked.png',
      'jordy_happy.png',
      'sp_jordy_study.png',
      'background_studyroom.png',
    ]);
    print('✅ preload images 완료');

    sceneEventManager = SceneEventManager(
        onShowScene: (scene) async {
          print("🧩 onShowScene 호출됨 → 씬 추가 시도: ${scene.runtimeType}");
          await add(scene);
          print("🧩 씬 추가 완료: ${scene.runtimeType}");
        });
    await runScenesIfNeeded();
  }

  Future<void> runScenesIfNeeded() async {
    if (_hasRunScenes) return;
    _hasRunScenes = true;
    await sceneEventManager.checkTimeBasedScenes();
  }

  void resumeGame() async {
    print("📲 RoomGame.resumeGame() called");
    // 씬이 다 제거됐으면 다시 보여줌

    if (children.isEmpty) {
      _hasRunScenes = false;
      await runScenesIfNeeded();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    print("🧹 RoomGame 자원 정리 중...");
    children.clear();
    sceneEventManager.dispose();
  }
}
