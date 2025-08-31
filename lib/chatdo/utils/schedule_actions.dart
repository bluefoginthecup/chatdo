import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../usecases/schedule_usecase.dart';
import '../../game/core/game_controller.dart';
import '../data/firestore/paths.dart';

final _store = FirestorePathsV1(FirebaseFirestore.instance);
DocumentReference<Map<String, dynamic>> _newRef(String uid, String id) =>
      _store.messages(uid).doc(id);


// 🔧 레거시 경로(구조: messages/{uid}/logs/{id}) — 폴백/정리용
DocumentReference<Map<String, dynamic>> _oldRef(String uid, String id) =>
         FirebaseFirestore.instance.collection('messages').doc(uid).collection('logs').doc(id);

/// 편집/삭제 다이얼로그 (신 경로 우선, 구경로 폴백)
Future<void> showEditOrDeleteDialog({
  required BuildContext context,
  required String docId,
  required String originalText,
  required String mode, // 'todo' | 'done'
  required DateTime currentDate,
  required VoidCallback onRefresh,
}) async {
  final controller = TextEditingController(text: originalText);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  Future<DocumentReference<Map<String, dynamic>>> pickRef() async {
    final nr = _newRef(uid, docId);
    final ns = await nr.get();
    if (ns.exists) return nr;

    final or = _oldRef(uid, docId);
    final os = await or.get();
    return os.exists ? or : nr; // 없으면 새 경로로 업서트
  }

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
            final ref = await pickRef();
            final path = ref.path;
            await ref.delete().catchError((_) {});               // 선택된 경로 삭제
            // 안전하게 양쪽 다 정리
            await _newRef(uid, docId).delete().catchError((_) {});
            await _oldRef(uid, docId).delete().catchError((_) {});
            Navigator.of(context).pop();
            onRefresh();
            debugPrint('🗑 deleted: $path (and attempted both)');
          },
        ),
        TextButton(
          child: const Text('저장'),
          onPressed: () async {
            final ref = await pickRef();
            // 신 스키마로 저장(content/updatedAt). date/type은 그대로 유지.
            await ref.set({
              'content': controller.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            Navigator.of(context).pop();
            onRefresh();
            debugPrint('💾 saved: ${ref.path}');
          },
        ),
      ],
    ),
  );
}

/// 할일↔한일 토글 (신 경로 기준, 구문서만 있으면 읽어서 업서트 후 사용)
Future<void> markAsOtherType({
  required String docId,
  required String currentMode, // 'todo' or 'done'
  required GameController gameController,
  required DateTime currentDate,
  required Future<void> Function() onRefresh,
  required BuildContext context,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // 1) 문서 선택: 신 → 구 폴백
  DocumentSnapshot<Map<String, dynamic>> snap;
  var ref = _newRef(uid, docId);
  snap = await ref.get();

  if (!snap.exists) {
    final old = _oldRef(uid, docId);
    final os = await old.get();
    if (!os.exists) {
      debugPrint('❌ markAsOtherType: document not found in both paths: $docId');
      return;
    }
    // 1-1) 구문서 데이터를 신 스키마로 업서트(migrate-lite)
    final d = os.data()!;
    final text = (d['content'] ?? d['text'] ?? '').toString();
    final typeStr = (d['type'] ?? d['mode'] ?? currentMode).toString();
    final rawDate = d['date'];
    final DateTime date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? currentDate;

    await ref.set({
      'uid': uid,
      'docId': docId,
      'content': text,
      'type': typeStr,
      'date': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
      'createdAt': d['createdAt'] is Timestamp
          ? d['createdAt']
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'tags': (d['tags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      if (d['imageUrl'] != null) 'imageUrl': d['imageUrl'],
      if (d['imageUrls'] != null) 'imageUrls': (d['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
      if (d['body'] != null) 'body': d['body'],
      if (d['originDate'] != null) 'originDate': d['originDate'],
    }, SetOptions(merge: true));

    // (선택) 구문서 정리하고 싶으면 아래 주석 해제
    // await old.delete().catchError((_) {});
    snap = await ref.get();
  }

  // 2) 엔트리 빌드(겹스키마 호환 파서 사용 권장)
  final entry = ScheduleEntry.fromFirestore(snap);

  // 3) 토글 타입 결정
  final newType = entry.type == ScheduleType.done ? ScheduleType.todo : ScheduleType.done;

  // 4) 단일 진실 경로: UseCase로 업데이트 (경로/스키마/포인트/프로바이더 일괄)
  await ScheduleUseCase.updateEntry(
    entry: entry,
    newType: newType,
    provider: context.read<ScheduleProvider>(),
    gameController: gameController,
    firestore: FirebaseFirestore.instance,
    userId: uid,
  );

  // 5) (선택) originDate 기록: done이 되는 첫 순간에만
  if (newType == ScheduleType.done && (entry.originDate == null || entry.originDate!.isEmpty)) {
    final ymd = "${currentDate.year.toString().padLeft(4, '0')}-"
        "${currentDate.month.toString().padLeft(2, '0')}-"
        "${currentDate.day.toString().padLeft(2, '0')}";
    await ref.set({'originDate': ymd}, SetOptions(merge: true));
  }

  // 6) 새로고침
  await onRefresh();
  debugPrint('🔁 toggled type → ${newType.name}: ${ref.path}');
}
