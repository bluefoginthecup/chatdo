import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/routine_model.dart';
import '../paths.dart'; // UserStorePaths / FirestorePathsV1 등

class RoutineRepo {
  RoutineRepo(this.paths);
  final UserStorePaths paths;

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String uid) {
    return paths.dailyRoutines(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> remove(String uid, String docId) {
    return paths.dailyRoutines(uid).doc(docId).delete();
  }

  Future<void> addOrUpdate(String uid, Routine r) async {
    final ref = paths.dailyRoutines(uid).doc(r.docId ?? paths.dailyRoutines(uid).doc().id);
    final data = r.toJson();
    data['userId'] = uid;
    data['createdAt'] ??= FieldValue.serverTimestamp();
    // 필요 시 date/Timestamp 정규화도 여기서
    await ref.set(data, SetOptions(merge: true));
  }
}
