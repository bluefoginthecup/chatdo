import '../models/schedule_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../game/core/game_controller.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final VoidCallback onUpdate;



  const ScheduleDetailScreen({
    Key? key,
    required this.entry,
    required this.gameController,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late ScheduleEntry _entry;
  late DateTime _date;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late bool _isEditing;


  bool _isRoutineFormOpen = false;
  List<String> _selectedDays = [];
  TimeOfDay? _selectedTime;
  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();

    _entry = widget.entry;
    _date = _entry.date;
    _titleController = TextEditingController(text: _entry.content);
    _bodyController = TextEditingController(text: _entry.body ?? '');
    _isEditing = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadEntry();
    });
  }

  Future<void> _updateDate(DateTime newDate) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({'date': newDate.toIso8601String().substring(0, 10)});
    setState(() {
      _entry = _entry.copyWith(date: newDate);
      _date = newDate;
    });
    widget.onUpdate();
  }

  Future<void> _deleteEntry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .delete();
    widget.onUpdate();
    if (mounted) Navigator.pop(context);
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

  Future<void> _saveRoutineToFirestore({
    required String title,
    required List<String> days,
    required TimeOfDay time,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final docRef = firestore.collection('daily_routines').doc(); // ✅ 문서 참조 먼저 만들고
    await docRef.set({
      'docId': docRef.id, // ✅ docId를 직접 저장
      'title': title,
      'days': days,
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _saveRoutineInfoToTodo(List<String> days, TimeOfDay time) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'routineInfo': {
        'days': List.from(_selectedDays),
        'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 보기'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                final userId = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('messages')
                    .doc(userId)
                    .collection('logs')
                    .doc(_entry.docId)
                    .update({
                  'content': _titleController.text.trim(),
                  'body': _bodyController.text.trim(),
                });
                setState(() {
                  _entry = _entry.copyWith(
                    content: _titleController.text.trim(),
                    body: _bodyController.text.trim(),
                  );
                  _isEditing = false;
                });
                widget.onUpdate();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: const Text('정말로 삭제하시겠습니까?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                  ],
                ),
              );
              if (confirm == true) await _deleteEntry();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isEditing
                  ? TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '제목',
                ),
              )
                  : Text(
                _entry.content,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onDoubleTap: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (newDate != null) await _updateDate(newDate);
                },
                child: Text(
                  '날짜: $dateStr (더블탭해서 변경)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (_entry.imageUrl != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _entry.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _isEditing
                  ? TextField(
                controller: _bodyController,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '본문',
                ),
              )
                  : Text(
                _entry.body ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              if (_entry.routineInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '루틴 등록됨',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('반복 요일: ${(_entry.routineInfo!['days'] as List<dynamic>).join(", ")}'),
                      Text('알림 시간: ${_entry.routineInfo!['time']}'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                      _isRoutineFormOpen = !_isRoutineFormOpen;
                      });
                      },
                      icon: const Icon(Icons.repeat),
                      label: const Text('루틴 등록'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 태그 추가 다이얼로그 띄우기
                    },
                    icon: const Icon(Icons.label), // 라벨 아이콘
                    label: const Text('태그 추가'),
                  ),
                ],
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isRoutineFormOpen
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('반복 요일을 선택하세요:', style: TextStyle(fontSize: 16)),
                    Wrap(
                      spacing: 8.0,
                      children: _days.map((day) {
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
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                      child: Text(_selectedTime == null
                          ? '알림 시간 선택'
                          : '선택된 시간: ${_selectedTime!.format(context)}'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_selectedDays.isEmpty || _selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('요일과 시간을 모두 선택하세요')),
                          );
                          return;
                        }
                        final copiedDays = List<String>.from(_selectedDays);
                        try {
                          await _saveRoutineToFirestore(
                            title: _entry.content,
                            days: copiedDays,
                            time: _selectedTime!,
                          );
                          await _saveRoutineInfoToTodo(copiedDays, _selectedTime!);

                          setState(() {
                            _entry = _entry.copyWith(
                              routineInfo: {
                                'days': copiedDays,
                                'time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                              },
                            );
                            _isRoutineFormOpen = false;
                            _selectedDays.clear();
                            _selectedTime = null;

                          });


                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('루틴이 등록되었습니다')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('루틴 등록 실패: $e')),
                          );
                          debugPrint ('루틴 등록 실패: $e');
                        }
                      },
                      child: const Text('루틴 저장'), // ← 이거 추가해야 돼유!
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
