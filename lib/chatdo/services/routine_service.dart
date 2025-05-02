// lib/services/routine_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine_model.dart'; // 모델 불러오기

class RoutineService {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('daily_routines');

  // 루틴 저장

  static Future<void> saveRoutine(Routine routine) async {
    final data = routine.toJson();
    data['createdAt'] = FieldValue.serverTimestamp(); // ✅ 서버 시간으로 createdAt 덮어쓰기
    await _collection.doc(routine.docId).set(data);
  }
  // 루틴 수정
  static Future<void> updateRoutine(Routine routine) async {
    await _collection.doc(routine.docId).update(routine.toJson());
  }

  // 루틴 삭제
  static Future<void> deleteRoutine(String docId) async {
    await _collection.doc(docId).delete();
  }

  // 루틴 하나 불러오기 (선택)
  static Future<Routine?> getRoutine(String docId) async {
    final doc = await _collection.doc(docId).get();
    if (doc.exists) {
      return Routine.fromJson(doc.data()!);
    }
    return null;
  }
}
