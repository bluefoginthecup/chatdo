// lib/chatdo/screens/schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../../game/core/game_controller.dart';
import '../widgets/schedule_entry_tile.dart';

/// Generic list screen for todo/done entries on a given date.
class ScheduleListScreen extends StatelessWidget {
  final ScheduleType type;
  final DateTime date;
  final GameController gameController;
  final Future<void> Function() onRefresh;

  const ScheduleListScreen({
    Key? key,
    required this.type,
    required this.date,
    required this.gameController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final entries = provider.getEntriesForDate(date, type);

    if (entries.isEmpty) {
      return Center(
        child: Text(
          type == ScheduleType.todo ? '할일이 없습니다.' : '완료된 일이 없습니다.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ScheduleEntryTile(
          entry: entry,
          gameController: gameController,
          onRefresh: onRefresh,
        );
      },
    );
  }
}

// lib/chatdo/providers/schedule_provider.dart (add method)
extension ScheduleProviderExtensions on ScheduleProvider {
  List<ScheduleEntry> getEntriesForDate(DateTime date, ScheduleType type) {
    final key = DateTime(date.year, date.month, date.day);
    final all = type == ScheduleType.todo ? todos : dones;
    return all.where((e) {
      final d = e.date;
      return d.year == key.year && d.month == key.month && d.day == key.day;
    }).toList();
  }

  /// Example reload trigger; you can implement to re-fetch from Firestore
  Future<void> reload() async {
    notifyListeners();
  }
}
