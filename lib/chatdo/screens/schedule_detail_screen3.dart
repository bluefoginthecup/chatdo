import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/routine_model.dart';
import '../services/routine_service.dart';
import '../../game/core/game_controller.dart';
import '../models/schedule_entry.dart';// 게임 컨트롤러 import 추가

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleEntry entry;
  final GameController gameController; // ✅ gameController 추가
  final Future<void> Function()? onUpdate;

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
  bool _isRoutineFormOpen = false;

  final List<String> _daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  final Set<String> _selectedDays = {};
  final Map<String, String> _dayTimeMap = {};

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
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

  // 루틴 저장할 때 부분
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

    // ✅ 포인트 추가만 남긴다!
    widget.gameController.addPoints(10); // 포인트 10점 추가

    // ✅ 저장 후 onUpdate 호출해서 리스트 갱신
    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }

    // ✅ 씬 전환은 따로 안 한다! (RoomGame 쪽 흐름에서 따로 처리)

    setState(() {
      _entry = _entry.copyWith(
        routineInfo: {
          'docId': routine.docId,
          'days': routine.days,
        },
      );
      _isRoutineFormOpen = false;
      _dayTimeMap.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('루틴이 저장되었습니다! 포인트 추가!')),
    );
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
        'days': routine.days,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할일 상세'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _entry.content,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              child: _isRoutineFormOpen
                  ? _buildRoutineForm()
                  : const SizedBox.shrink(),
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
    final daysMap = _entry.routineInfo!['days'] as Map<String, dynamic>;

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
