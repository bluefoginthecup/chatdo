// lib/chatdo/usecases/delete_entry.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_entry.dart';
import '../data/firestore/repos/message_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('삭제하시겠습니까?'),
      content: const Text('이 일정과 연결된 이미지도 함께 삭제됩니다.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
      ],
    ),
  ) ??
      false;
}

// 반환값을 bool로 바꿈: 삭제 실행했으면 true, 취소면 false
Future<bool> deleteEntryUnified(BuildContext context, ScheduleEntry entry) async {
  final ok = await _confirmDelete(context);
  if (!ok) return false;
  final uid  = FirebaseAuth.instance.currentUser!.uid;
  final repo = context.read<MessageRepo>();
  await repo.removeCascadeByEntry(uid, entry);
  return true;
}

