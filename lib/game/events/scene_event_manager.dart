import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/sick_scene.dart';
import 'package:chatdo/game/scenes/workout_scene.dart';
import 'package:chatdo/game/scene_conditions/sick_scene_condition.dart';
import 'package:chatdo/game/scene_conditions/workout_scene_condition.dart';

/// 시간 기반 이벤트로 조르디 씬을 보여주는 매니저
class SceneEventManager {
  /// 씬이 선택되었을 때 실행할 콜백
  final void Function(dynamic scene) onShowScene;

  SceneEventManager({required this.onShowScene});

  /// 시간 조건에 따라 이벤트 씬 체크
  Future<bool> checkTimeBasedScenes() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // 밤 9시 조건
    if (now.hour == 21 && prefs.getString('lastNightScene') != today) {
      final shown = await _showRandomNightScene();
      if (shown) {
        prefs.setString('lastNightScene', today);
        return true;
      }
    }

    return false;
  }

  Future<bool> _showRandomNightScene() async {
    final sceneOptions = <MapEntry<Future<bool> Function(), dynamic Function()>>[
      MapEntry(SickSceneCondition.shouldShow, () => SickScene()),
      MapEntry(WorkoutSceneCondition.shouldShow, () => WorkoutScene()),
    ];


    final validScenes = <dynamic Function()>[];

    for (final option in sceneOptions) {
      if (await option.key()) {
        validScenes.add(option.value);
      }
    }


    if (validScenes.isNotEmpty) {
      final randomScene = validScenes[Random().nextInt(validScenes.length)]();
      onShowScene(randomScene);
      return true;
    }

    return false;
  }

}
