import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/nlp_parser.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../widgets/chat_input_box.dart';


class HomeChatScreen extends StatefulWidget {
  const HomeChatScreen({super.key});

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen> {
  final List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(text);
    });


    final result = NlpParser.parse(text);
    if (result != null) {
      final newEntry = ScheduleEntry(
        date: result.date,
        type: result.type,
        content: result.content,
      );

      // 상태에 추가
      Provider.of<ScheduleProvider>(context, listen: false).addEntry(newEntry);
    }

    _controller.clear();

    // 나중에 여기에 파싱 & 일정 저장 로직 추가 예정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatDo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ChatInputBox(
              controller: _controller,
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),

        ],
      ),
    );
  }
}
