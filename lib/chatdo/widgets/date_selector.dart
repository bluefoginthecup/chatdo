// date_selector.dart
import 'package:flutter/material.dart';
import '../models/enums.dart'; //

class DateSelector extends StatelessWidget {
  final Mode mode;
  final DateTag selected;
  final Function(DateTag) onChanged;

  const DateSelector({required this.mode, required this.selected, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final tags = mode == Mode.todo
        ? [DateTag.today, DateTag.tomorrow]
        : [DateTag.today, DateTag.yesterday];

    return Wrap(
      spacing: 8,
      children: tags.map((tag) {
        final isSelected = selected == tag;
        final label = tag == DateTag.today ? '오늘'
            : tag == DateTag.tomorrow ? '내일'
            : '어제';
        return OutlinedButton(
          onPressed: () => onChanged(tag),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? Colors.teal.shade100 : null,
          ),
          child: Text(label),
        );
      }).toList(),
    );
  }
}
