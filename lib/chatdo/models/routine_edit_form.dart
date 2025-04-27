import 'package:flutter/material.dart';
import '../models/routine_model.dart';

class RoutineEditForm extends StatefulWidget {
  final Routine? initialRoutine;
  final void Function(Routine updatedRoutine) onSave;

  const RoutineEditForm({
    Key? key,
    this.initialRoutine,
    required this.onSave,
  }) : super(key: key);

  @override
  _RoutineEditFormState createState() => _RoutineEditFormState();
}

class _RoutineEditFormState extends State<RoutineEditForm> {
  late TextEditingController _titleController;
  Map<String, String> _days = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialRoutine?.title ?? '',
    );
    _days = Map<String, String>.from(widget.initialRoutine?.days ?? {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedRoutine = Routine(
      docId: widget.initialRoutine?.docId ?? '', // 수정할 때 docId 유지
      title: _titleController.text.trim(),
      days: _days,
      userId: widget.initialRoutine?.userId ?? '', // 수정 시 userId도 유지
      createdAt: widget.initialRoutine?.createdAt ?? DateTime.now(),
    );

    widget.onSave(updatedRoutine);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: '루틴 제목'),
        ),
        const SizedBox(height: 16),
        // 요일/시간 입력 폼 (간단 버전으로)
        Wrap(
          spacing: 8,
          children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
            return ElevatedButton(
              onPressed: () async {
                final time = await _pickTime(context, day);
                if (time != null) {
                  setState(() {
                    _days[day] = time;
                  });
                }
              },
              child: Text(_days.containsKey(day) ? '$day: ${_days[day]}' : day),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Future<String?> _pickTime(BuildContext context, String day) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }
}
