// chat_input_box.dart
import 'package:flutter/material.dart';

enum Mode { todo, done }
enum DateTag { today, tomorrow, yesterday }

class ChatInputBox extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String text, Mode mode, DateTime date) onSubmitted;

  const ChatInputBox({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  State<ChatInputBox> createState() => _ChatInputBoxState();
}

class _ChatInputBoxState extends State<ChatInputBox> {
  Mode? _selectedMode;
  DateTag? _selectedDateTag;
  final List<String> _messageLog = [];

  List<DateTag> get currentDateOptions => _selectedMode == Mode.todo
      ? [DateTag.today, DateTag.tomorrow]
      : [DateTag.today, DateTag.yesterday];

  String getDateTagLabel(DateTag tag) {
    switch (tag) {
      case DateTag.today:
        return '오늘';
      case DateTag.tomorrow:
        return '내일';
      case DateTag.yesterday:
        return '어제';
    }
  }

  DateTime resolveDate(DateTag tag) {
    final now = DateTime.now();
    switch (tag) {
      case DateTag.today:
        return now;
      case DateTag.tomorrow:
        return now.add(const Duration(days: 1));
      case DateTag.yesterday:
        return now.subtract(const Duration(days: 1));
    }
  }

  void _handleSubmit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _selectedMode == null || _selectedDateTag == null) return;

    widget.onSubmitted(text, _selectedMode!, resolveDate(_selectedDateTag!));

    setState(() {
      _messageLog.add(text);
      widget.controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: _selectedMode == null
              ? [
            _buildModeButton(Mode.todo, '할일'),
            const SizedBox(width: 8),
            _buildModeButton(Mode.done, '한일'),
          ]
              : currentDateOptions.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildDateButton(tag),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                onSubmitted: (_) => _handleSubmit(),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.teal,
              onPressed: _handleSubmit,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._messageLog.map((msg) => Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(msg),
          ),
        )),
      ],
    );
  }

  Widget _buildModeButton(Mode mode, String label) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
          _selectedDateTag = null;
        });
      },
      child: Text(label),
    );
  }

  Widget _buildDateButton(DateTag tag) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (_selectedDateTag == tag) {
            _selectedDateTag = null;
            _selectedMode = null;
          } else {
            _selectedDateTag = tag;
          }
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: _selectedDateTag == tag ? Colors.teal.shade100 : null,
      ),
      child: Text(getDateTagLabel(tag)),
    );
  }
}
