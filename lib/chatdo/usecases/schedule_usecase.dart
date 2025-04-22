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
    );

    // 상태 교체 (replaceEntry 사용)
    provider.replaceEntry(entry, updated);

    // 포인트 처리
    if (oldType == ScheduleType.todo && newType == ScheduleType.done) {
      gameController.addPoints(100);
    } else if (oldType == ScheduleType.done && newType == ScheduleType.todo) {
      gameController.subtractPoints(10);
    }
    // Firestore 업데이트
    if (entry.docId != null) {
      try {
        await firestore
            .collection('messages')
            .doc(userId)
            .collection('logs')
            .doc(entry.docId)
            .update({
          'content': updated.content,
          'date': updated.date.toIso8601String().substring(0, 10),
          'mode': updated.type.name,
          'timestamp': updated.createdAt.toIso8601String(),
        });
        print('✅ Firestore 업데이트 성공: ${updated.content}');
      } catch (e) {
        print('🔥 Firestore 업데이트 실패: $e');
      }
    } else {
      print('⚠️ Firestore 업데이트 실패: docId가 null임');
    }
  }
}
