// schedule_provider.dart (수정된 버전)

import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../models/game_sync_data.dart';

class ScheduleProvider with ChangeNotifier {
  final List<ScheduleEntry> _todos = [];
  final List<ScheduleEntry> _dones = [];

  int point = 0;
  int level = 1;
  int _previousLevel = 1;

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

  void replaceEntry(ScheduleEntry oldEntry, ScheduleEntry newEntry) {
    // id 기반 필터링
    _todos.removeWhere((e) => e.docId == oldEntry.docId);
    _dones.removeWhere((e) => e.docId == oldEntry.docId);

    if (newEntry.type == ScheduleType.todo) {
      _todos.add(newEntry);
    } else {
      _dones.add(newEntry);
    }
    notifyListeners();
  }

  int calculateStreak() {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final hasDone = _dones.any((e) => _isSameDay(e.date, date));
      if (hasDone) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  GameSyncData getGameSyncData() {
    final today = DateTime.now();
    final completedToday = _dones.any((e) => _isSameDay(e.date, today));
    final lastTodoText = _dones.isNotEmpty ? _dones.last.content : null;

    return GameSyncData(
      point: point,
      level: level,
      completedCount: _dones.length,
      consecutiveDays: calculateStreak(),
      lastTodoText: lastTodoText,
      leveledUp: level > _previousLevel,
      completedToday: completedToday,
    );
  }
}
