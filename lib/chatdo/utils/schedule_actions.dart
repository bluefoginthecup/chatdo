import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../usecases/schedule_usecase.dart';
import '../../game/core/game_controller.dart';

Future<void> showEditOrDeleteDialog({
  required BuildContext context,
  required String docId,
  required String originalText,
  required String mode, // 'todo' or 'done'
  required DateTime currentDate,
  required VoidCallback onRefresh,
}) async {
  final controller = TextEditingController(text: originalText);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('편집 또는 삭제'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '내용을 입력하세요'),
      ),
      actions: [
        TextButton(
          child: const Text('삭제'),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('messages')
                .doc(uid)
                .collection('logs')
                .doc(docId)
                .delete();
            Navigator.of(context).pop();
            onRefresh();
          },
        ),
        TextButton(
          child: const Text('저장'),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('messages')
                .doc(uid)
                .collection('logs')
                .doc(docId)
                .update({'content': controller.text});
            Navigator.of(context).pop();
            onRefresh();
          },
        ),
      ],
    ),
  );
}

Future<void> markAsOtherType({
  required String docId,
  required String currentMode, // 'todo' or 'done'
  required GameController gameController,
  required DateTime currentDate,
  required Future<void> Function() onRefresh, // ✅ Future로 변경
  required BuildContext context,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('messages')
      .doc(uid)
      .collection('logs')
      .doc(docId);

  final doc = await docRef.get();
  if (!doc.exists) return;

  final entry = ScheduleEntry(
    content: doc['content'],
    date: DateTime.parse(doc['date']),
    createdAt: DateTime.parse(doc['timestamp']),
    type: currentMode == 'todo' ? ScheduleType.todo : ScheduleType.done,
    docId: docId,
  );

  final newType = currentMode == 'todo' ? ScheduleType.done : ScheduleType.todo;

  await ScheduleUseCase.updateEntry(
    entry: entry,
    newType: newType,
    provider: context.read<ScheduleProvider>(),
    gameController: gameController,
    firestore: FirebaseFirestore.instance,
    userId: uid,
  );

  await onRefresh(); // ✅ 반드시 완료 후 새로고침
}
