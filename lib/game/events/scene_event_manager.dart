import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatdo/game/scenes/sick_scene.dart';
import 'package:chatdo/game/scenes/workout_scene.dart';
import 'package:chatdo/game/scenes/day_events/sat_night_scene.dart';
import 'package:chatdo/game/scenes/day_events/sun_pm_scene.dart';
import 'package:chatdo/game/scene_conditions/sick_scene_condition.dart';
import 'package:chatdo/game/scene_conditions/workout_scene_condition.dart';
import 'package:chatdo/game/scene_conditions/day_events/sat_night_scene_condition.dart';
import 'package:chatdo/game/scene_conditions/day_events/sun_pm_scene_condition.dart';
import 'package:flutter/foundation.dart';


class SceneEventManager {
  final void Function(dynamic scene) onShowScene;

  SceneEventManager({required this.onShowScene});

  Future<bool> checkTimeBasedScenes() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (now.hour == 21 && prefs.getString('lastNightScene') != today) {
      final scenesToShow = await gatherScenesToShow();
      for (final builder in scenesToShow) {
        builder(() => onShowScene);
      }
      prefs.setString('lastNightScene', today);
      return scenesToShow.isNotEmpty;
    }
    return false;
  }

  Future<List<void Function(VoidCallback)>> gatherScenesToShow() async {
    final result = <void Function(VoidCallback)>[];

    print('🧪 이벤트 조건 체크 시작');
    final eventCandidates = <MapEntry<Future<bool> Function(), void Function(VoidCallback)>>[
      MapEntry(SatNightSceneCondition.shouldShow, (onCompleted) => onShowScene(SatNightScene(onCompleted: onCompleted))),
      MapEntry(SunPmSceneCondition.shouldShow, (onCompleted) => onShowScene(SunPmScene(onCompleted: onCompleted))),
    ];

    final validEvents = <void Function(VoidCallback)>[];
    for (final entry in eventCandidates) {
      final conditionResult = await entry.key();
      print('🧪 조건 ${entry.key} → $conditionResult');
      if (conditionResult) {
        validEvents.add(entry.value);
      }
    }
    if (validEvents.isNotEmpty) {
      final selected = validEvents[Random().nextInt(validEvents.length)];
      print('🎯 이벤트 씬 선택됨');
      result.add(selected);
    } else {
      print('🚫 이벤트 씬 없음');
    }

    final mandatoryScenes = <MapEntry<Future<bool> Function(), void Function(VoidCallback)>>[
      MapEntry(SickSceneCondition.shouldShow, (onCompleted) => onShowScene(SickScene(onCompleted: onCompleted))),
      MapEntry(WorkoutSceneCondition.shouldShow, (onCompleted) => onShowScene(WorkoutScene(onCompleted: onCompleted))),
    ];

    for (final entry in mandatoryScenes) {
      if (await entry.key()) {
        result.add(entry.value);
      }
    }

    return result;
  }
}
