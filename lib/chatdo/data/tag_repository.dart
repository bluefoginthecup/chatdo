import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_tag.dart';
import 'firestore/paths.dart';

class TagRepository {
  static const List<String> _builtInNames = [
    '운동', '건강', '스페인어', '베이킹', '방석재고', '세금',
    '영수증', '매장관리', '재고채우기', '자수', '챗두', '언젠가', '기타',
  ];

static List<UserTag> getBuiltInTags() {
return _builtInNames.map((name) => UserTag(name: name, isBuiltin: true)).toList();
}

static Future<List<UserTag>> loadAllTags(String uid) async {
final builtIn = getBuiltInTags();
    final store = currentPaths(FirebaseFirestore.instance);
    final snapshot = await store.customTags(uid).orderBy('name').get();


   final custom = snapshot.docs
        .map((doc) => UserTag.fromFirestore(doc.id, doc.data()))
        .where((tag) => tag.name.trim().isNotEmpty && !_builtInNames.contains(tag.name))
        .toList();


     // 중복 제거 후 이름순 정렬
     final all = [...builtIn, ...custom];
     all.sort((a, b) => a.name.compareTo(b.name));
     return all;
}

static Future<void> saveTag(String uid, UserTag tag) async {
if (tag.isBuiltin) return;
     final store = currentPaths(FirebaseFirestore.instance);
     final id = tag.name.trim();
     if (id.isEmpty) return;
     await store.customTags(uid).doc(id).set(
       {
         'name': id,
         ...tag.toJson(), // 색/즐겨찾기 등 있으면 병합
         'updatedAt': FieldValue.serverTimestamp(),
       },
       SetOptions(merge: true),
     );
}

static Future<void> deleteTag(String uid, String name) async {

     final store = currentPaths(FirebaseFirestore.instance);
     await store.customTags(uid).doc(name).delete();
}
}
