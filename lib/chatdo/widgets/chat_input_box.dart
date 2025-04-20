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
    widget.controller.clear();
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
      ],
    );
  }

  ButtonStyle _buttonStyle({
    required bool isSelected,
    required Color baseColor,
  }) {
    return OutlinedButton.styleFrom(
      backgroundColor: isSelected ? Colors.teal.shade100 : baseColor,
      side: BorderSide(color: isSelected ? Colors.teal : Colors.grey),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildModeButton(Mode mode, String label) {
    final bool isSelected = _selectedMode == mode;
    final Color baseColor = Colors.amber.shade100;

    return OutlinedButton(
      onPressed: () async {
        setState(() {
          _selectedMode = mode;
          _selectedDateTag = null;
        });
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          setState(() {});
        }
      },
      style: _buttonStyle(isSelected: isSelected, baseColor: baseColor),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.teal.shade900 : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDateButton(DateTag tag) {
    final bool isSelected = _selectedDateTag == tag;
    final Color baseColor = Colors.teal.shade50;

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
      style: _buttonStyle(isSelected: isSelected, baseColor: baseColor),
      child: Text(
        getDateTagLabel(tag),
        style: TextStyle(
          color: isSelected ? Colors.teal.shade900 : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}