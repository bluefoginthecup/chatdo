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

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _date = _entry.date;
    _titleController = TextEditingController(text: _entry.content);
    _bodyController = TextEditingController(text: _entry.body ?? '');
    _isEditing = false;
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
            ],
          ),
        ),
      ),
    );
  }
}
