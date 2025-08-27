import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_tag.dart';

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

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('custom_tags')
        .get();

    final custom = snapshot.docs
        .map((doc) => UserTag.fromFirestore(doc.id, doc.data()))
        .where((tag) => !_builtInNames.contains(tag.name))
        .toList();

    return [...builtIn, ...custom];
  }

  static Future<void> saveTag(String uid, UserTag tag) async {
    if (tag.isBuiltin) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('custom_tags')
        .doc(tag.name)
        .set(tag.toJson());
  }

  static Future<void> deleteTag(String uid, String name) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('custom_tags')
        .doc(name)
        .delete();
  }
}
