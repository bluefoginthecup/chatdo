// schedule_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule_entry.dart';
import '../models/game_sync_data.dart';
import '../../game/core/game_controller.dart';

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

  void addEntry(ScheduleEntry entry) {
    if (entry.type == ScheduleType.todo) {
      _todos.add(entry);
    } else {
      _dones.add(entry);
      point += 10;
      _previousLevel = level;
      level = 1 + (point ~/ 100);
    }
    notifyListeners();
  }

  // 할일에서 한일로 이동
  void moveToDone(ScheduleEntry entry) {
    _todos.remove(entry);
    _dones.add(ScheduleEntry(
      date: entry.date,
      type: ScheduleType.done,
      content: entry.content,
      createdAt: entry.createdAt,
    ));
    point += 10;
    _previousLevel = level;
    level = 1 + (point ~/ 100);
    notifyListeners();
  }

  Future<void> completeTodoEntry({
    required ScheduleEntry entry,
    required GameController gameController,
    required FirebaseFirestore firestore,
    required String userId,
  }) async {
    _todos.remove(entry);
    final doneEntry = ScheduleEntry(
      content: entry.content,
      date: entry.date,
      createdAt: entry.createdAt,
      type: ScheduleType.done,
    );
    _dones.add(doneEntry);
    point += 10;
    _previousLevel = level;
    level = 1 + (point ~/ 100);
    notifyListeners();

    gameController.sync(getGameSyncData());

    await firestore
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .add({
      'content': doneEntry.content,
      'mode': 'done',
      'date': doneEntry.date.toIso8601String().substring(0, 10),
      'timestamp': doneEntry.createdAt.toIso8601String(),
    });
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
