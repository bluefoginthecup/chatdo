import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:chatdo/game/registry/scene_registry_health.dart';
import 'package:chatdo/game/registry/scene_registry_day_events.dart';
import '/game/scenes/room_scene.dart';
import 'package:chatdo/game/scenes/intro_scene.dart';


// 씬 생성자 타입: dynamic Function(VoidCallback onCompleted)
typedef SceneBuilder = dynamic Function(VoidCallback onCompleted);

class SceneEventManager {
  final void Function(dynamic scene) onShowScene;

  SceneEventManager({required this.onShowScene});

  Future<bool> checkTimeBasedScenes() async {
    final scenesToShow = await gatherScenesToShow();
    _playScenesSequentially(scenesToShow);
    return scenesToShow.isNotEmpty;
  }


  Future<List<SceneBuilder>> gatherScenesToShow() async {
    final result = <SceneBuilder>[];

    print('🧪 이벤트 조건 체크 시작');
    final eventCandidates = <MapEntry<Future<bool> Function(), SceneBuilder>>[
      ...buildDayEventScenes(), // ✅ 여기 들어가야 무작위 씬 가능
    ];
    final validEvents = <SceneBuilder>[];
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

    final mandatoryScenes = [
      ...buildHealthScenes(),

    ];

    for (final entry in mandatoryScenes) {
      final conditionResult = await entry.key();
      print('🧪 조건 ${entry.key} → $conditionResult');
      if (conditionResult) {
        result.add(entry.value);
      }
    }

    // ✅ 조건/루틴 씬이 아무것도 없을 경우 → IntroScene 추가
    if (result.isEmpty) {
      print("🟡 큐가 비어 있음 → IntroScene 추가");
      result.add((onCompleted) {
        print("🎯 IntroScene builder 실행됨");
        return IntroScene(onCompleted: onCompleted);
      });
    }

    print("📦 최종 씬 큐 수: ${result.length}");
    for (var builder in result) {
      final scene = builder(() {
        print("🧪 (미리보기) onCompleted 콜백 호출됨");
      });
      print("📦 포함된 씬: ${scene.runtimeType}");
    }

    return result;
  }


  void _playScenesSequentially(List<SceneBuilder> builders, [int index = 0]) {
    if (index >= builders.length) {
      print("🏁 모든 씬 완료 → RoomScene 진입");
      onShowScene(RoomScene());
      return;
    }
    print("🎬 실행 중인 씬 인덱스: $index / 총 ${builders.length}");

    final builder = builders[index];
    final scene = builder(() {
      print("▶️ onCompleted 호출됨 → 다음 씬으로");
      _playScenesSequentially(builders, index + 1);
    });

    print("🎯 실행 중인 씬: ${scene.runtimeType}");
    if (scene == null) print("❌ scene 반환값이 null입니다!");

    onShowScene(scene);
  }
}
