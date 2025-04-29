// mode_selector.dart
import 'package:flutter/material.dart';
import '../models/enums.dart'; //


class ModeSelector extends StatelessWidget {
  final Mode selected;
  final Function(Mode) onChanged;

  const ModeSelector({required this.selected, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: Mode.values.map((mode) {
        final isSelected = selected == mode;
        final label = mode == Mode.todo ? '할일' : '한일';
        return OutlinedButton(
          onPressed: () => onChanged(mode),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? Colors.teal.shade100 : null,
          ),
          child: Text(label),
        );
      }).toList(),
    );
  }
}
