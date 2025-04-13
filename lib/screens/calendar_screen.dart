// calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input_box.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TextEditingController _controller = TextEditingController();

  void _handleSendMessage(String text, Mode mode, DateTime date) {
    if (text.trim().isEmpty) return;

    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
    );

    Provider.of<ScheduleProvider>(context, listen: false).addEntry(entry);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Text('여기에 캘린더가 표시됩니다'),
          ),
        ),
        ChatInputBox(
          controller: _controller,
          onSubmitted: _handleSendMessage,
        ),
      ],
    );
  }
}