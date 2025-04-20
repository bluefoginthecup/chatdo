// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';

class ScheduleProvider with ChangeNotifier {
  final List<ScheduleEntry> _todos = [];
  final List<ScheduleEntry> _dones = [];

  List<ScheduleEntry> get todos {
    final sorted = [..._todos];
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(sorted);
  }

  List<ScheduleEntry> get dones {
    final sorted = [..._dones];
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(sorted);
  }

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
      createdAt: entry.createdAt,
    ));
    notifyListeners();  // 상태 업데이트
  }

}
