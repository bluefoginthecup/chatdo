// lib/chatdo/widgets/schedule_entry_tile.dart
import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../screens/schedule_detail_screen.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart';


/// Reusable tile widget for a schedule entry (todo or done)
class ScheduleEntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final VoidCallback onRefresh;

  const ScheduleEntryTile({
    Key? key,
    required this.entry,
    required this.gameController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDone = entry.type == ScheduleType.done;
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          // Toggle status (todo <-> done)
          markAsOtherType(
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
      title: GestureDetector(
        onTap: () {
          // Navigate to detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScheduleDetailScreen(
                entry: entry,
                gameController: gameController,
                onUpdate: onRefresh,
              ),
            ),
          );
        },
        child: Text(
          entry.content,
          style: TextStyle(
            color: isDone ? Colors.grey : Colors.red,
          ),
        ),
      ),
    );
  }
}
