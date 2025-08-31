// schedule_usecase.dart (updateEntry → Firestore 문서 업데이트 방식 적용)
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../../game/core/game_controller.dart';
import '../data/firestore/paths.dart';

class ScheduleUseCase {
  static Future<void> updateEntry({
    required ScheduleEntry entry,
    required ScheduleType newType,
    required ScheduleProvider provider,
    required GameController gameController,
    required FirebaseFirestore firestore,
    required String userId,
  }) async {
    final paths = FirestorePathsV1(firestore);
    // id 보장
    final id = entry.docId ?? paths.messages(userId).doc().id;

    final oldType = entry.type;
    final updated = ScheduleEntry(
      content: entry.content,
      date: entry.date,
      type: newType,
      createdAt: entry.createdAt,
      docId: id,
      tags: entry.tags,
      imageUrl: entry.imageUrl,
      imageUrls: entry.imageUrls,
      body: entry.body,
      timestamp: DateTime.now(),
    );

    print('🧪 updated.body = ${updated.body}');
    // 상태 교체 (replaceEntry 사용)
    provider.replaceEntry(entry, updated);

    // 포인트 처리
    if (oldType == ScheduleType.todo && newType == ScheduleType.done) {
      gameController.addPoints(100);
    } else if (oldType == ScheduleType.done && newType == ScheduleType.todo) {
      gameController.subtractPoints(10);
    }

    try {
      // 🔧 스키마 통일: text/type/date(Timestamp)
      final utcDay = DateTime.utc(
          updated.date.year, updated.date.month, updated.date.day);

      await paths.messages(userId).doc(id).set({
        'uid': userId,
        'docId': id,
        'text': updated.content,                 // ← content → text
        'type': updated.type.name,               // ← type 고정
        'date': Timestamp.fromDate(utcDay),      // ← 문자열 말고 Timestamp(자정)
        'createdAt': updated.createdAt != null
            ? Timestamp.fromDate(updated.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'tags': updated.tags ?? const <String>[],
        if (updated.imageUrl != null) 'imageUrl': updated.imageUrl,
        if (updated.imageUrls != null) 'imageUrls': updated.imageUrls,
        if (updated.body != null) 'body': updated.body,
      }, SetOptions(merge: true));

      print('✅ Firestore 문서 생성 또는 업데이트 완료: ${updated.content}');
    } catch (e) {
      print('🔥 Firestore 업데이트 실패: $e');
    }
  }
}
