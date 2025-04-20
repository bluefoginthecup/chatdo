// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';

class ScheduleProvider with ChangeNotifier {
  final List<ScheduleEntry> _todos = [];
  final List<ScheduleEntry> _dones = [];

  List<ScheduleEntry> get todos => List.unmodifiable(_todos);
  List<ScheduleEntry> get dones => List.unmodifiable(_dones);

  void addEntry(ScheduleEntry entry) {
    if (entry.type == ScheduleType.todo) {
      _todos.add(entry);
    } else {
      _dones.add(entry);
    }
    notifyListeners();
  }

  // 할일에서 한일로 이동
  void moveToDone(ScheduleEntry entry) {
    // 할일 목록에서 제거
    _todos.remove(entry);
    // 한일 목록에 추가
    _dones.add(ScheduleEntry(
      date: entry.date,
      type: ScheduleType.done,
      content: entry.content,
    ));
    notifyListeners();  // 상태 업데이트
  }

  // 완료한 일 목록을 최신순으로 정렬
  List<ScheduleEntry> get sortedDones {
    // 날짜 기준으로 내림차순 정렬
    _dones.sort((a, b) => b.date.compareTo(a.date));
    return _dones;
  }

}
