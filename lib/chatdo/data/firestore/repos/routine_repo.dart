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

  /// 저장(merge). 저장된 문서 id를 리턴.
     Future<String> addOrUpdate(String uid, Routine r) async {
         final docId = r.docId ?? paths.dailyRoutines(uid).doc().id;
         final ref = paths.dailyRoutines(uid).doc(docId);
         final data = Map<String, dynamic>.from(r.toJson());
     
         // 스키마 통일: uid/createdAt/updatedAt/docId
         data['uid'] = uid;                      // userId 말고 uid로 통일
         data['docId'] = docId;
         data['createdAt'] ??= FieldValue.serverTimestamp();
         data['updatedAt'] = FieldValue.serverTimestamp();
     
         // TODO: 날짜/시간 필드 정규화 필요하면 여기서 처리
         // if (data['time'] is TimeOfDay) { ... }  // etc.
     
         await ref.set(data, SetOptions(merge: true));
         return docId;
       }
   
     /// 단건 조회(필요하면)
     Future<DocumentSnapshot<Map<String, dynamic>>> get(String uid, String docId) {
         return paths.dailyRoutines(uid).doc(docId).get();
       }
}
