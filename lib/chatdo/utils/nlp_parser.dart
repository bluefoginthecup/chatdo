import '../models/schedule_entry.dart';  // ScheduleEntry import

class NlpParser {
  static ScheduleEntry? parse(String input) {
    input = input.trim();

    DateTime? parsedDate;

    // "어제" 처리
    if (input.contains('어제')) {
      parsedDate = DateTime.now().subtract(const Duration(days: 1));  // 어제
    }
    // 요일 (월, 화, 수, 목, 금, 토, 일) 처리
    else if (RegExp(r'월|화|수|목|금|토|일').hasMatch(input)) {
      parsedDate = _getWeekdayDate(input);  // 요일에 맞는 날짜 계산
    }
    // "내일", "모레" 처리
    else if (input.contains('내일')) {
      parsedDate = DateTime.now().add(const Duration(days: 1));  // 내일
    } else if (input.contains('모레')) {
      parsedDate = DateTime.now().add(const Duration(days: 2));  // 모레
    }
    // "이번 주", "다음 주" 처리
    else if (input.contains('이번 주') || input.contains('다음 주')) {
      parsedDate = _getNextWeekDate(DateTime.now(), input);  // 이번 주 / 다음 주
    }
    // "4월 11일" 처럼 특정 날짜 파싱
    else if (RegExp(r'\d{1,2}일').hasMatch(input)) {
      final day = int.parse(RegExp(r'\d{1,2}').firstMatch(input)!.group(0)!);
      final currentMonth = DateTime.now().month;
      parsedDate = DateTime(DateTime.now().year, currentMonth, day);  // 특정 날짜
    }
    // 기본값: 오늘
    else {
      parsedDate = DateTime.now();
    }

    // 유형 파싱 (할일 / 한일)
    ScheduleType? type;
    if (input.contains('할 일')|| input.contains('할일')|| input.contains('야돼')) {
      type = ScheduleType.todo;
    } else if (input.contains('한 일') || input.contains('한일') || input.contains('었어')) {
      type = ScheduleType.done;
    } else {
      type = ScheduleType.todo;  // 기본적으로 할일로 처리
    }

    // 내용 파싱
    final splitKeyword = input.contains(',') ? ',' : (input.contains(' ') ? ' ' : '');
    if (splitKeyword.isEmpty) return null;

    final parts = input.split(splitKeyword);
    if (parts.length < 2) return null;

    final content = parts.sublist(1).join(splitKeyword).trim();

    return ScheduleEntry.fromParsedEntry(parsedDate, type, content);
  }

  // 요일 처리 (월요일, 화요일 등)
  static DateTime _getWeekdayDate(String input) {
    final weekdayNames = {
      '월': DateTime.monday,
      '화': DateTime.tuesday,
      '수': DateTime.wednesday,
      '목': DateTime.thursday,
      '금': DateTime.friday,
      '토': DateTime.saturday,
      '일': DateTime.sunday,
    };

    final today = DateTime.now();
    final targetWeekday = weekdayNames.entries
        .firstWhere((entry) => input.contains(entry.key))
        .value;

    final difference = targetWeekday - today.weekday;
    return today.add(Duration(days: difference));
  }

  // 날짜 계산: 이번 주 / 다음 주 날짜
  static DateTime _getNextWeekDate(DateTime currentDate, String input) {
    if (input.contains('이번 주')) {
      return currentDate;  // 이번 주는 현재 날짜
    } else if (input.contains('다음 주')) {
      return currentDate.add(const Duration(days: 7));  // 다음 주는 일주일 후
    }
    return currentDate;  // 기본값 현재 날짜
  }
}
