import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/routine_model.dart';
import '../models/schedule_entry.dart'; // 할일 모델
import '../services/routine_service.dart';
import '../../game/core/game_controller.dart'; // 게임 컨트롤러

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final Future<void> Function()? onUpdate; // 리스트 새로고침 콜백

  const ScheduleDetailScreen({
    Key? key,
    required this.entry,
    required this.gameController,
    this.onUpdate,
  }) : super(key: key);

  @override
  _ScheduleDetailScreenState createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late ScheduleEntry _entry;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isEditing = false;
  bool _isRoutineFormOpen = false;

  final List<String> _daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  final Set<String> _selectedDays = {};
  final Map<String, String> _dayTimeMap = {};

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _titleController = TextEditingController(text: _entry.content);
    _bodyController = TextEditingController(text: _entry.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entry.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _entry = _entry.copyWith(date: picked);
      });
    }
  }

  Future<void> _pickTimeForSelectedDays() async {
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
        _selectedDays.clear();
      });
    }
  }
  Future<void> _reloadEntry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .get();

    if (doc.exists) {
      setState(() {
        _entry = ScheduleEntry.fromJson(doc.data()!);
      });
    }
  }

  Future<void> _saveRoutineInfoToTodo(Routine routine) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'routineInfo': {
        'docId': routine.docId,
        'days': Map<String, String>.from(routine.days),
      },
    });

  }


  Future<void> _saveRoutineFromAccordion() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('daily_routines').doc();

    final routine = Routine(
      docId: docRef.id,
      title: _entry.content,
      days: Map<String, String>.from(_dayTimeMap),
      userId: userId,
      createdAt: DateTime.now(),
    );

    await RoutineService.saveRoutine(routine);
    await _saveRoutineInfoToTodo(routine);
    await _reloadEntry();

    widget.gameController.addPoints(10); // 포인트 추가

    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }

    setState(() {
      _isRoutineFormOpen = false;
      _dayTimeMap.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('루틴이 저장되었습니다! 포인트 추가!')),
    );
  }

  Future<void> _saveChanges() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'content': _titleController.text,
      'body': _bodyController.text,
      'date': Timestamp.fromDate(_entry.date),
    });

    setState(() {
      _entry = _entry.copyWith(
        content: _titleController.text,
        body: _bodyController.text,
      );
      _isEditing = false;
    });

    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('할일이 수정되었습니다!')),
    );
  }

  Future<void> _deleteEntry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('이 할일을 정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );


    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('logs')
          .doc(_entry.docId)
          .delete();

      if (widget.onUpdate != null) {
        await widget.onUpdate!();
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할일 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onDoubleTap: _pickDate,
              child: Text(
                '${_entry.date.year}-${_entry.date.month.toString().padLeft(2, '0')}-${_entry.date.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            )
                : Text(
              _entry.content,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: '본문'),
              maxLines: null,
            )
                : Text(
              _entry.body ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_entry.imageUrl != null)
              Image.network(
                _entry.imageUrl!,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              child: Text(_isEditing ? '수정 완료' : '수정'),
            ),
            if (_isEditing)
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('저장'),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isRoutineFormOpen = !_isRoutineFormOpen;
                });
              },
              icon: const Icon(Icons.repeat),
              label: const Text('루틴 등록'),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isRoutineFormOpen ? _buildRoutineForm() : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            if (_entry.routineInfo != null) _buildRoutineInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('반복 요일을 선택하세요:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _daysOfWeek.map((day) {
            final isSelected = _selectedDays.contains(day);
            return ChoiceChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedDays.isEmpty ? null : _pickTimeForSelectedDays,
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
                onPressed: () {
                  setState(() {
                    _dayTimeMap.remove(entry.key);
                  });
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _dayTimeMap.isEmpty ? null : _saveRoutineFromAccordion,
          child: const Text('루틴 저장하기'),
        ),
      ],
    );
  }

  Widget _buildRoutineInfo() {
    if (_entry.routineInfo == null || _entry.routineInfo!['days'] == null) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> rawDaysMap = _entry.routineInfo!['days'];

    final daysMap = rawDaysMap.map((key, value) => MapEntry(key.toString(), value.toString()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('루틴 등록됨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...daysMap.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
      ],
    );
  }

}
