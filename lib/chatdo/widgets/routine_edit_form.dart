// lib/forms/routine_edit_form.dart

import 'package:flutter/material.dart';

class RoutineEditForm extends StatefulWidget {
  final Map<String, String>? initialDays; // 수정할 때 초기 데이터 넘길 수 있게
  final Function(Map<String, String>) onSave; // 저장하면 부모로 넘겨주는 콜백

  const RoutineEditForm({
    Key? key,
    this.initialDays,
    required this.onSave,
  }) : super(key: key);

  @override
  _RoutineEditFormState createState() => _RoutineEditFormState();
}

class _RoutineEditFormState extends State<RoutineEditForm> {
  final List<String> _daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  final Set<String> _selectedDays = {}; // 지금 선택된 요일들
  final Map<String, String> _dayTimeMap = {}; // 최종 저장될 요일별 시간

  @override
  void initState() {
    super.initState();
    if (widget.initialDays != null) {
      _dayTimeMap.addAll(widget.initialDays!);
    }
  }

  Future<void> _selectTimeForSelectedDays() async {
    if (_selectedDays.isEmpty) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        for (var day in _selectedDays) {
          _dayTimeMap[day] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
        _selectedDays.clear(); // 선택 초기화
      });
    }
  }

  void _removeDay(String day) {
    setState(() {
      _dayTimeMap.remove(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('요일을 선택하세요:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _daysOfWeek.map((day) {
            return ChoiceChip(
              label: Text(day),
              selected: _selectedDays.contains(day),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectTimeForSelectedDays,
          child: const Text('선택한 요일에 시간 설정'),
        ),
        const SizedBox(height: 24),
        const Text('설정된 요일과 시간:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _dayTimeMap.entries.map((entry) {
            return ListTile(
              title: Text('${entry.key} - ${entry.value}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeDay(entry.key),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_dayTimeMap); // 저장할 때 부모로 Map 넘기기
          },
          child: const Text('저장하기'),
        ),
      ],
    );
  }
}
