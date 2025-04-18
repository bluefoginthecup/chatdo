import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SyncService {
  static final _syncBox = Hive.box<Map>('syncQueue');

  // ✅ 1. 이벤트 추가
  static Future<void> addEvent(String type, Map<String, dynamic> data) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _syncBox.add({
      'type': type,
      'data': data,
      'timestamp': timestamp,
    });
  }

  // ✅ 2. 온라인 상태면 전체 업로드 시도
  static Future<void> uploadAllIfConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final batch = FirebaseFirestore.instance.batch();

    final entries = _syncBox.toMap(); // key: index, value: Map
    final keysToDelete = [];

    for (final entry in entries.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value['type'] == 'add_message') {
        final data = value['data'];
        final docRef = FirebaseFirestore.instance
            .collection('messages')
            .doc(userId)
            .collection('logs')
            .doc(data['id']); // 메시지 ID 기반 저장

        batch.set(docRef, data);
        keysToDelete.add(key);
      }

      // 여기서 다른 타입(ex. 포인트 추가 등)도 처리 가능
    }

    if (keysToDelete.isNotEmpty) {
      await batch.commit();
      for (final key in keysToDelete) {
        await _syncBox.delete(key);
      }
    }
  }
}
