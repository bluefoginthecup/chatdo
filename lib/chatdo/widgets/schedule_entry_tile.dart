// lib/chatdo/widgets/schedule_entry_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_entry.dart';
import '../screens/schedule_detail_screen.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart';

/// 일정 항목 하나를 표시하는 재사용 가능한 타일 위젯
class ScheduleEntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final Future<void> Function() onRefresh;

  const ScheduleEntryTile({
    Key? key,
    required this.entry,
    required this.gameController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDone = entry.type == ScheduleType.done;
    final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);

    return ListTile(
      leading: entry.imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          entry.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      )
          : GestureDetector(
        onTap: () async {
          await markAsOtherType(
            docId: entry.docId!,
            currentMode: entry.type.name,
            gameController: gameController,
            currentDate: entry.date,
            onRefresh: onRefresh,
            context: context,
          );
        },
        child: Icon(
          isDone ? Icons.check_circle_outline : Icons.circle_outlined,
          color: isDone ? Colors.grey : Colors.red,
        ),
      ),
      title: entry.imageUrl != null
          ? const Text('[사진]', style: TextStyle(color: Colors.grey))
          : Text(
        entry.content,
        style: TextStyle(
          color: isDone ? Colors.grey : Colors.red,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        dateStr,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => ScheduleDetailScreen(
              entry: entry,
              gameController: gameController,
              onUpdate: onRefresh,
            ),
          ),
        )
            .then((_) => onRefresh());
      },
    );
  }
}
