// tool/new_scene.dart
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('📛 사용법: dart run tool/new_scene.dart [scene_name]');
    exit(1);
  }

  final name = args[0].toLowerCase(); // e.g. tue_pm
  final className = name
      .split('_')
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .join(); // TuePm

  final sceneClassName = '${className}Scene';
  final conditionClassName = '${className}SceneCondition';
  final dialogueVarName = 'dialogue$className';

  final sceneCode = '''
import 'package:chatdo/features/game/scenes/dialogue_scene_base.dart';
import 'package:chatdo/features/game/story/dialogue_$name.dart';

class $sceneClassName extends DialogueSceneBase {
  $sceneClassName({super.onCompleted});

  @override
  List<Map<String, String>> get dialogueData => $dialogueVarName;

  @override
  String get bgmPath => 'assets/sounds/default_theme.m4a';

  @override
  String get characterImagePath => 'jordy_casual.png';
}
''';

  final conditionCode = '''
class $conditionClassName {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    final result = true; // TODO: 조건 수정 필요
    print('🧪 [$sceneClassName] now=\$now → \$result');
    return result;
  }
}
''';

  final dialogueCode = '''
final List<Map<String, String>> $dialogueVarName = [
  {"speaker": "조르디", "line": "$className 씬입니다. 여기에 대사를 작성하세요."},
];
''';

  final base = Directory.current.path;
  File('$base/lib/game/scenes/day_events/${name}_scene.dart')
      .writeAsStringSync(sceneCode);
  File('$base/lib/game/scene_conditions/day_events/${name}_scene_condition.dart')
      .writeAsStringSync(conditionCode);
  File('$base/lib/game/story/dialogue_$name.dart')
      .writeAsStringSync(dialogueCode);

  final registryPath = '$base/lib/game/registry/scene_registry_day_events.dart';
  final registryFile = File(registryPath);
  if (!registryFile.existsSync()) {
    print('⚠️ scene_registry_day_events.dart 파일이 존재하지 않습니다.');
    exit(1);
  }

  final registryLines = registryFile.readAsLinesSync();

  final insertIndex =
      registryLines.indexWhere((line) => line.contains('List<MapEntry'));
  if (insertIndex == -1) {
    print('❌ scene 목록 시작점을 찾을 수 없습니다.');
    exit(1);
  }

  final importLines = [
    "import 'package:chatdo/features/game/scenes/day_events/${name}_scene.dart';",
    "import 'package:chatdo/features/game/scene_conditions/day_events/${name}_scene_condition.dart';",
  ];

  final entryBlock = '''  MapEntry(
    $conditionClassName.shouldShow,
    (onCompleted) {
      print("🎯 $sceneClassName builder 실행됨");
      return $sceneClassName(onCompleted: onCompleted);
    },
  ),''';

  final updatedLines = [
    ...importLines,
    ...registryLines.map((line) {
      if (line.contains('List<MapEntry')) {
        return line;
      } else {
        return line;
      }
    }),
  ];

  // append entryBlock to the list manually (naive but safe)
  final insertPos =
      updatedLines.lastIndexWhere((line) => line.trim().endsWith('],'));
  if (insertPos != -1) {
    updatedLines.insert(insertPos, entryBlock);
  }

  registryFile.writeAsStringSync(updatedLines.join('\n'));

  print('✅ $sceneClassName, 조건, dialogue 파일 생성 완료!');
  print('📌 scene_registry_day_events.dart에 자동 등록 완료');
  print('✏️ 조건 로직 및 대사 내용은 직접 수정하세요');
}
