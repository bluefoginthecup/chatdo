import 'package:chatdo/game/scenes/day_events/tue_am_scene.dart';
import 'package:chatdo/game/scene_conditions/day_events/tue_am_scene_condition.dart';
import 'package:flutter/foundation.dart';
import 'package:chatdo/game/scenes/day_events/sat_night_scene.dart';
import 'package:chatdo/game/scene_conditions/day_events/sat_night_scene_condition.dart';
import 'package:chatdo/game/scenes/day_events/sun_pm_scene.dart';
import 'package:chatdo/game/scene_conditions/day_events/sun_pm_scene_condition.dart';
import 'package:chatdo/game/scenes/day_events/mon_am_scene.dart';
import 'package:chatdo/game/scene_conditions/day_events/mon_am_scene_condition.dart';
import 'package:chatdo/game/scenes/day_events/mon_noon_scene.dart';
import 'package:chatdo/game/scene_conditions/day_events/mon_noon_scene_condition.dart';


typedef SceneBuilder = dynamic Function(VoidCallback onCompleted);

List<MapEntry<Future<bool> Function(), SceneBuilder>> buildDayEventScenes() => [
  MapEntry(
    SatNightSceneCondition.shouldShow,
        (onCompleted) {
      print("🎯 SatNightScene builder 실행됨");
      return SatNightScene(onCompleted: onCompleted);
    },
  ),
  MapEntry(
    SunPmSceneCondition.shouldShow,
        (onCompleted) {
      print("🎯 SunPmScene builder 실행됨");
      return SunPmScene(onCompleted: onCompleted);
    },
  ),
  MapEntry(
    MonAmSceneCondition.shouldShow,
        (onCompleted) {
      print("🎯 MonAmScene builder 실행됨");
      return MonAmScene(onCompleted: onCompleted);
    },
  ),
  MapEntry(
    MonNoonSceneCondition.shouldShow,
        (onCompleted) {
      print("🎯 MonNoonScene builder 실행됨");
      return MonNoonScene(onCompleted: onCompleted);
    },
  ),
  MapEntry(
    TueAmSceneCondition.shouldShow,
        (onCompleted) {
      print("🎯 TueAmScene builder 실행됨");
      return TueAmScene(onCompleted: onCompleted);
    },
  ),
];