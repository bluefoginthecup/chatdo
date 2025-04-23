// lib/chatdo/screens/schedule_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../utils/schedule_actions.dart';
import '../usecases/schedule_usecase.dart';
import '../providers/schedule_provider.dart';
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
  late DateTime _date;
  late String _content;
  bool _editingContent = false;

  @override
  void initState() {
    super.initState();
    _date = widget.entry.date;
    _content = widget.entry.content;
  }

  Future<void> _updateDate(DateTime newDate) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(widget.entry.docId)
        .update({'date': DateFormat('yyyy-MM-dd').format(newDate)});
    setState(() => _date = newDate);
    widget.onUpdate();
  }

  Future<void> _updateContent(String newContent) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(widget.entry.docId)
        .update({'content': newContent});
    setState(() => _content = newContent);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(_date);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: () async {
            final newTitle = await _showTextEditDialog('제목 편집', _content);
            if (newTitle != null && newTitle.trim().isNotEmpty) {
              await _updateContent(newTitle.trim());
            }
          },
          child: Text(
            _content,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '삭제',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('정말 삭제할까요?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('삭제')),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseFirestore.instance
                    .collection('messages')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('logs')
                    .doc(widget.entry.docId)
                    .delete();
                widget.onUpdate();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('+ 이미지 추가 기능은 추후 구현 예정')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.entry.imageUrl != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.entry.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '내용 (더블탭해서 수정):',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onDoubleTap: () async {
                final newText = await _showTextEditDialog('내용 수정', _content);
                if (newText != null && newText.trim().isNotEmpty) {
                  await _updateContent(newText.trim());
                }
              },
              child: Text(_content),
            ),
            const SizedBox(height: 16),
            // TODO: 이미지 추가 시 여기에 뿌려줄 수 있음
          ],
        ),
      ),
    );
  }

  Future<String?> _showTextEditDialog(String title, String initialText) async {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('저장')),
        ],
      ),
    );
  }
}
