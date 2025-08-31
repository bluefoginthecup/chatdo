// lib/forms/routine_edit_form.dart

import 'package:flutter/material.dart';
import '../utils/weekdays.dart';

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
  final List<String> _daysOfWeek = kWeekdaysKo;
  final Set<String> _selectedDays = {}; // 지금 선택된 요일들
  final Map<String, String> _dayTimeMap = {}; // 최종 저장될 요일별 시간

  @override
  void initState() {
    super.initState();
    if (widget.initialDays != null) {
      _dayTimeMap.addAll(widget.initialDays!);
    }
  }

   // 'HH:mm' → TimeOfDay
   TimeOfDay _parseTime(String hhmm) {
     final parts = hhmm.split(':');
     if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
     final h = int.tryParse(parts[0]) ?? 8;
     final m = int.tryParse(parts[1]) ?? 0;
     return TimeOfDay(hour: h, minute: m);
   }
 
   // 단일 요일 시간 편집
   Future<void> _editTimeForDay(String day) async {
     final initial = _dayTimeMap[day] != null
         ? _parseTime(_dayTimeMap[day]!)
         : const TimeOfDay(hour: 8, minute: 0);
     final picked = await showTimePicker(
       context: context,
       initialTime: initial,
     );
     if (picked != null) {
       setState(() {
         _dayTimeMap[day] =
             '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
       });
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
    final sortedEntries = sortWeekdayMap(_dayTimeMap);
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

             const SizedBox(height: 8),
             Align(
               alignment: Alignment.centerRight,
               child: TextButton(
                 onPressed: _selectedDays.isEmpty
                     ? null
                     : () => setState(() => _selectedDays.clear()),
                 child: const Text('선택 해제'),
               ),
             ),
        const SizedBox(height: 24),
        const Text('설정된 요일과 시간:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

    children: sortedEntries.map((entry) {
            return ListTile(
              title: Text('${entry.key} - ${entry.value}'),
    onTap: () => _editTimeForDay(entry.key), // 탭해서 시간 수정
    trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeDay(entry.key),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
    onPressed: _dayTimeMap.isEmpty
                   ? null
                   : () {
    widget.onSave(Map<String, String>.from(_dayTimeMap)); // 방어적 복사
    },
          child: const Text('저장하기'),
    ),
    ],
    );
    }
  }