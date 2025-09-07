// lib/data/firestore/repos/text_dictionary_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../paths.dart';

class TextDictionaryRepo {
  static Future<DocumentReference<Map<String, dynamic>>?> _getRef() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final db = FirebaseFirestore.instance;
    final ref = currentPaths(db).textDictionary(uid); // ✅ 문서 레퍼런스여야 함
    return ref;
  }

  /// 저장: 공백 정리 + 중복 제거 + merge
  static Future<void> save(List<String> entries) async {
    final ref = await _getRef();
    if (ref == null) return;

    // ✅ sanitize
    final cleaned = <String>[];
    final seen = <String>{};
    for (final e in entries) {
      final s = (e ?? '').trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) cleaned.add(s);
    }

    await ref.set({'entries': cleaned}, SetOptions(merge: true)); // ✅ merge
  }

  /// 로드: 없으면 빈 리스트, 공백 제거 + 중복 제거
  static Future<List<String>> load() async {
    final ref = await _getRef();
    if (ref == null) return [];

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return [];

    final raw = data['entries'];
    if (raw is! List) return [];

    // ✅ sanitize
    final out = <String>[];
    final seen = <String>{};
    for (final e in raw) {
      if (e is! String) continue;
      final s = e.trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) out.add(s);
    }
    // 디버그 확인용
    // print('[TextDictionaryRepo] loaded ${out.length} entries');

    return out;
  }
}
