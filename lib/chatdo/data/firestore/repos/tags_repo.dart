import 'package:cloud_firestore/cloud_firestore.dart';
import '../paths.dart';
import '../../../models/user_tag.dart';

class TagRepo {
  final UserStorePaths paths;
  TagRepo(this.paths);

  Stream<List<UserTag>> watch(String uid) =>
      paths.customTags(uid).snapshots().map(
              (s) => s.docs.map((d) => UserTag.fromFirestore(d.id, d.data())).toList()
      );

  Future<void> upsert(String uid, UserTag tag) =>
      paths.customTags(uid).doc(tag.name).set(tag.toJson(), SetOptions(merge: true));

  Future<void> remove(String uid, String name) =>
      paths.customTags(uid).doc(name).delete();
}
