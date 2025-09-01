import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  // 경로 컨벤션: users/{uid}/chat_images/{msgId}/{index}.{ext}
  static String buildImagePath({
    required String uid,
    required String msgId,
    required int index,
    required String ext, // jpg/png/webp
  }) => 'users/$uid/chat_images/$msgId/$index.$ext';

  static String _extOf(File f) {
    final name = f.path.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  static String _contentType(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  // 기존 imagePaths에서 다음 인덱스 계산
  static int nextImageIndex(List<String> paths) {
    final re = RegExp(r'/(\d+)\.(jpg|jpeg|png|webp)$', caseSensitive: false);
    int maxIdx = -1;
    for (final p in paths) {
      final m = re.firstMatch(p);
      if (m != null) {
        final idx = int.tryParse(m.group(1)!) ?? -1;
        if (idx > maxIdx) maxIdx = idx;
      }
    }
    return maxIdx + 1;
  }

  /// files를 업로드해서 Storage 경로(imagePaths)와 URL(과도기용)을 문서에 추가.
  /// - docId 없으면 새 문서 생성 후 그 id로 업로드.
  /// - 반환: 실제 추가된 storage 경로들
  static Future<List<String>> uploadAndAttachImages({
    required String collectionPathForUser, // 예: "users/$uid/messages"
    required String? docId,
    required List<File> files,
    required List<String> currentImagePaths,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final colRef = firestore.collection(collectionPathForUser);
    final DocumentReference<Map<String, dynamic>> docRef =
    (docId == null) ? colRef.doc() : colRef.doc(docId);

    // 새 문서면 최소 필드만 미리 생성(안전)
    if (docId == null) {
      await docRef.set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imagePaths': [],
        'imageUrls': [], // 과도기
      }, SetOptions(merge: true));
    }

    int idx = nextImageIndex(currentImagePaths);
    final newPaths = <String>[];
    final newUrls  = <String>[]; // 과도기

    for (final file in files) {
      final ext = _extOf(file);
      final path = buildImagePath(uid: uid, msgId: docRef.id, index: idx, ext: ext);
      final ref = storage.ref(path);

      await ref.putFile(file, SettableMetadata(contentType: _contentType(ext)));

      newPaths.add(ref.fullPath);
      newUrls.add(await ref.getDownloadURL()); // 과도기 저장, 나중에 제거 가능
      idx++;
    }

    await docRef.set({
      'imagePaths': FieldValue.arrayUnion(newPaths),
      'imageUrls': FieldValue.arrayUnion(newUrls),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return newPaths;
  }
}
