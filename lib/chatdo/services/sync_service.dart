// lib/chatdo/services/sync_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/message.dart';
import '../data/firestore/paths.dart';

class SyncService {
  static Box<Map>? _box; // 지연 오픈

  static Future<Box<Map>> _ensureBox() async {
    _box ??= await Hive.openBox<Map>('syncQueue');
    return _box!;
  }

  // 이벤트 추가
  static Future<void> addEvent(String type, Map<String, dynamic> data) async {
    final box = await _ensureBox();
    await box.add({
      'type': type,
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // 이미지 업로드 enqueuer (홈챗에서 호출)
  static Future<void> enqueueImageUpload({
    required String uid,
    required String messageId,
    required List<String> localPaths,
  }) async {
    await addEvent('upload_images', {
      'uid': uid,
      'messageId': messageId,
      'paths': localPaths,
    });
    // 즉시 한 번 시도
    await uploadAllIfConnected();
  }

  // 온라인이면 큐 처리
  static Future<void> uploadAllIfConnected() async {
    final net = await Connectivity().checkConnectivity();
    if (net == ConnectivityResult.none) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final box = await _ensureBox();
    final entries = box.toMap(); // {key: Map}
    if (entries.isEmpty) return;

    // key 정렬(오래된 것부터)
    final keys = entries.keys.toList()
      ..sort((a, b) {
        final ma = entries[a] as Map; final mb = entries[b] as Map;
        return ((ma['ts'] as int?) ?? 0).compareTo(((mb['ts'] as int?) ?? 0));
      });

    for (final key in keys) {
      final job = entries[key] as Map;
      final type = (job['type'] ?? '').toString();
      final data = (job['data'] as Map).cast<String, dynamic>();

      try {
        switch (type) {
          case 'add_message':
            await _handleAddMessage(data);
            await box.delete(key);
            break;

          case 'upload_images':
            await _handleUploadImages(data);
            await box.delete(key);
            break;

          default:
          // 알 수 없는 타입은 버림
            await box.delete(key);
        }
      } catch (e) {
        // 실패하면 일단 중단(다음에 재시도) — 필요하면 backoff/재시도카운트 추가
        break;
      }
    }
  }

  // users/{uid}/messages/{id} 로 저장(merge)
  static Future<void> _handleAddMessage(Map<String, dynamic> data) async {
    final uid = data['uid'] as String? ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw 'no uid';
    final id = data['id'] as String?; // 메시지 문서 id
    if (id == null || id.isEmpty) throw 'no id';

    final paths = FirestorePathsV1(FirebaseFirestore.instance);
    await paths.messages(uid).doc(id).set(data, SetOptions(merge: true));

  }

  // Storage 업로드 → Firestore URL 패치 → Hive 업데이트
  static Future<void> _handleUploadImages(Map<String, dynamic> data) async {
    final uid = data['uid'] as String?;
    final messageId = data['messageId'] as String?;
    final localPaths = (data['paths'] as List).cast<String>();
    if (uid == null || messageId == null) throw 'upload_images: bad payload';

    // 1) 업로드 진행 표시 (Hive 상태 uploading)
    final mbox = Hive.box<Message>('messages');
    dynamic targetKey; Message? old;
    for (final k in mbox.keys) {
      final m = mbox.get(k);
      if (m is Message && m.id == messageId) { targetKey = k; old = m; break; }
    }
    if (targetKey != null && old != null) {
      await mbox.put(targetKey, old.copyWith(uploadState: 'uploading'));
    }
    // 2) Storage 업로드
    final urls = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      final file = File(localPaths[i]);
      final ref = FirebaseStorage.instance
          .ref('chat_images/$uid/$messageId/$i.jpg');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
// 3) Firestore에 URL 반영 (기존 URL과 머지)
       final store = FirestorePathsV1(FirebaseFirestore.instance);
        final existingUrls = (old?.imageUrls ?? const <String>[]);
        // 중복 제거해서 합치기
        final mergedUrls = [...{...existingUrls, ...urls}];
        await store.messages(uid).doc(messageId).set(
          {
            'imageUrls': mergedUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    // 4) Hive 패치(상태 done + URL 치환)
    if (targetKey != null && old != null) {
      await mbox.put(targetKey, old.copyWith(
        imageUrl: old.imageUrl ?? (urls.isNotEmpty ? urls.first : null),
        imageUrls: (old.imageUrls ?? <String>[])..addAll(urls),
        uploadState: 'done',
      ));
    }
  }
}
