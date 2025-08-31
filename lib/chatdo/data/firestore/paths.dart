import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 경로 매퍼(모델 의존 X, Map 기반)
abstract class UserStorePaths {
  CollectionReference<Map<String, dynamic>> messages(String uid);
  CollectionReference<Map<String, dynamic>> dailyRoutines(String uid);
  CollectionReference<Map<String, dynamic>> customTags(String uid); // ← 컬렉션(문서=태그)
}

class FirestorePathsV1 implements UserStorePaths {
  final FirebaseFirestore db;
  FirestorePathsV1(this.db);

  @override
  CollectionReference<Map<String, dynamic>> messages(String uid) =>
      db.collection('users').doc(uid).collection('messages');

  @override
  CollectionReference<Map<String, dynamic>> dailyRoutines(String uid) =>
      db.collection('users').doc(uid).collection('daily_routines');

  @override
  CollectionReference<Map<String, dynamic>> customTags(String uid) =>
      db.collection('users').doc(uid).collection('custom_tags');
}
 /// 현재 활성 경로 버전 선택기
 UserStorePaths currentPaths(FirebaseFirestore db) {
     return FirestorePathsV1(db);
     // 경로 바꾸면 여기만 V2로 갈아끼우면 됨:
     // return FirestorePathsV2(db);
   }