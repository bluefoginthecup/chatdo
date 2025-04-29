// schedule_usecase.dart (updateEntry → Firestore 문서 업데이트 방식 적용)
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../../game/core/game_controller.dart';

class ScheduleUseCase {
  static Future<void> updateEntry({
    required ScheduleEntry entry,
    required ScheduleType newType,
    required ScheduleProvider provider,
    required GameController gameController,
    required FirebaseFirestore firestore,
    required String userId,
  }) async {
    final oldType = entry.type;
    final updated = ScheduleEntry(
      content: entry.content,
      date: entry.date,
      type: newType,
      createdAt: entry.createdAt,
      docId: entry.docId,
      tags: entry.tags,
    );

    // 상태 교체 (replaceEntry 사용)
    provider.replaceEntry(entry, updated);

    // 포인트 처리
    if (oldType == ScheduleType.todo && newType == ScheduleType.done) {
      gameController.addPoints(100);
    } else if (oldType == ScheduleType.done && newType == ScheduleType.todo) {
      gameController.subtractPoints(10);
    }

    try {
      final docRef = firestore
          .collection('messages')
          .doc(userId)
          .collection('logs')
          .doc(entry.docId);

      await docRef.set({
        'content': updated.content,
        'date': updated.date.toIso8601String().substring(0, 10),
        'mode': updated.type.name,
        'timestamp': Timestamp.fromDate(updated.createdAt),
        'docId': updated.docId,
        'order': 0, // 기본 order. 나중에 지정 가능
        if (entry.imageUrl != null) 'imageUrl': entry.imageUrl,
        if (entry.imageUrls != null) 'imageUrls': entry.imageUrls,
        'tags': entry.tags,
      });

      print('✅ Firestore 문서 생성 또는 업데이트 완료: ${updated.content}');
    } catch (e) {
      print('🔥 Firestore 업데이트 실패: $e');
    }
  }
}
