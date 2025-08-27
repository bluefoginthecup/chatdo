import 'package:cloud_firestore/cloud_firestore.dart';
import '../paths.dart';
import '../../../models/schedule_entry.dart'; // ScheduleEntry에 toJson/fromJson 있음

class RoutineRepo {
  final UserStorePaths paths;
  RoutineRepo(this.paths);

  Stream<List<Map<String, dynamic>>> watch(String uid) =>
      paths.dailyRoutines(uid)
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs.map((d) => {'docId': d.id, ...d.data()}).toList());

  Future<String> add(String uid, ScheduleEntry e) async {
    final map = e.toJson();
    map['uid'] = uid;
    map['createdAt'] ??= FieldValue.serverTimestamp();
    // e.date가 DateTime이면 Timestamp로 보정
    if (map['date'] is DateTime) {
      map['date'] = Timestamp.fromDate(map['date']);
    }
    final doc = await paths.dailyRoutines(uid).add(map);
    return doc.id;
  }

  Future<void> update(String uid, String id, ScheduleEntry e) {
    final map = e.toJson();
    map['uid'] = uid;
    if (map['date'] is DateTime) {
      map['date'] = Timestamp.fromDate(map['date']);
    }
    return paths.dailyRoutines(uid).doc(id).set(map, SetOptions(merge: true));
  }

  Future<void> remove(String uid, String id) =>
      paths.dailyRoutines(uid).doc(id).delete();

}