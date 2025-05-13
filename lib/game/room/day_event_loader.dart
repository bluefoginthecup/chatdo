
import 'package:flame/components.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'day_event.dart';


// ✅ 2. DayEvent 모델에 fromJson 생성자 추가
typedef Vec2 = List<double>; // 예: [100, 400]




// ✅ 3. DayEventLoader 클래스: json 불러와서 매칭된 이벤트 리턴


class DayEventLoader {
  static Future<List<DayEvent>> loadAllEvents() async {
    final jsonString = await rootBundle.loadString('assets/data/day_events.json');
    final List list = json.decode(jsonString);
    return list.map((e) => DayEvent.fromJson(e)).toList();
  }

  static Future<DayEvent> getCurrentEvent(DateTime now) async {
    final allEvents = await loadAllEvents();
    final weekday = now.weekday;
    final hour = now.hour;

    for (final event in allEvents) {
      final start = event.hourStart;
      final end = event.hourEnd;
      final wday = event.weekday;

      if ((wday == null || wday == weekday) &&
          start != null &&
          end != null &&
          hour >= start &&
          hour < end) {
        return event;
      }
    }
  // fallback
    print('⚠️ fallback DayEvent 리턴됨');
    return DayEvent(
      id: 'default',
      backgroundImage: 'background.png',
      jordy: JordyConfig(
        spriteImage: 'jordy_idle.png',
        position: Vector2(250, 400),
        dialogueList: [
          '어서오세요, 아가씨!',
        '날씨가 화창하죠?'],
      ),
      girl: GirlConfig(
        position: Vector2(100, 400),
      ),
    );

  }
}
