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

class ScheduleDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(entry.date);
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.content),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '편집',
            onPressed: () {
              showEditOrDeleteDialog(
                context: context,
                docId: entry.docId!,
                originalText: entry.content,
                mode: entry.type.name,
                currentDate: entry.date,
                onRefresh: () {
                  onUpdate();
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: '날짜 변경',
            onPressed: () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: entry.date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (newDate != null) {
                await ScheduleUseCase.updateEntry(
                  entry: entry,
                  newType: entry.type,
                  provider: Provider.of<ScheduleProvider>(context, listen: false),
                  gameController: gameController,
                  firestore: FirebaseFirestore.instance,
                  userId: FirebaseAuth.instance.currentUser!.uid,
                );
                onUpdate();
                Navigator.of(context).pop();
              }
            },
          ),
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
                    .doc(entry.docId)
                    .delete();
                onUpdate();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '날짜: $dateStr',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '내용:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(entry.content),
            const SizedBox(height: 16),
            // TODO: 메모나 이미지 등 추가 구현
          ],
        ),
      ),
    );
  }
}