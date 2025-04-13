// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore에 사용자 데이터 저장
  Future<void> saveUserData(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
    });
  }
}
