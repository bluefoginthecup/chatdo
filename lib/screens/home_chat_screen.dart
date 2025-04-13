import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_entry.dart';
import '../widgets/chat_input_box.dart';


class HomeChatScreen extends StatefulWidget {
  const HomeChatScreen({super.key});

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen> {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ChatInputBox(
        controller: _controller,
        onSubmitted: _handleSendMessage,
      ),
    );
  }
}
