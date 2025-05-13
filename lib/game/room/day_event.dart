// ✅ 1. DayEvent 모델 정의
import 'package:flame/components.dart';

class DayEvent {
  final String id;
  final int? weekday;
  final int? hourStart;
  final int? hourEnd;
  final String backgroundImage;
  final JordyConfig jordy;
  final GirlConfig girl;


  DayEvent({
    required this.id,
    this.weekday,
    this.hourStart,
    this.hourEnd,
    required this.backgroundImage,
    required this.jordy,
    required this.girl,
  });

  factory DayEvent.fromJson(Map<String, dynamic> json) {
    return DayEvent(
      id: json['id'],
      weekday: json['weekday'],
      hourStart: json['hourStart'],
      hourEnd: json['hourEnd'],
      backgroundImage: json['backgroundImage'],
      jordy: JordyConfig.fromJson(json['jordy']),
      girl: GirlConfig.fromJson(json['girl']),
    );
  }
}

class JordyConfig {
  final String spriteImage;
  final Vector2 position;
  final String? animationName;
  final List<String> dialogueList;


  JordyConfig({
    required this.spriteImage,
    required this.position,
    this.animationName,
    required this.dialogueList,
  });

  factory JordyConfig.fromJson(Map<String, dynamic> json) {
    return JordyConfig(
      spriteImage: json['spriteImage'],
      position: Vector2(
        (json['position'][0] as num).toDouble(),
        (json['position'][1] as num).toDouble(),
      ),
      animationName: json['animationName'],
      dialogueList: List<String>.from(json['dialogue']),
    );
  }
}

class GirlConfig {
  final Vector2 position;
  final String? animationName;

  GirlConfig({
    required this.position,
    this.animationName,
  });

  factory GirlConfig.fromJson(Map<String, dynamic> json) {
    return GirlConfig(
      position: Vector2(
        (json['position'][0] as num).toDouble(),
        (json['position'][1] as num).toDouble(),
      ),
      animationName: json['animationName'],
    );
  }
}
