import 'package:hive/hive.dart';
import '/chatdo/models/schedule_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<void> autoPostponeUnfinishedTasks() async {
  final box = await Hive.openBox<ScheduleEntry>('schedules');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(Duration(days: 1));

  final tasks = box.values.where((task) =>
  task.type == ScheduleType.todo &&
      !task.isFixedDate &&
      isSameDay(task.date, yesterday)
  );

  for (final task in tasks) {
    final updated = task.copyWith(
      date: today,
      postponedCount: task.postponedCount + 1,
    );

    final key = task.docId ?? task.hashCode.toString();
    await box.put(key, updated);

    if (updated.isSyncedWithFirebase) {
      await uploadScheduleToFirebase(updated); // 파이어베이스로 업데이트
    }
  }
}


Future<void> uploadScheduleToFirebase(ScheduleEntry entry) async {
  if (entry.docId == null) return;

  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  final docRef = FirebaseFirestore.instance
      .collection('messages')
      .doc(userId)
      .collection('logs')
      .doc(entry.docId);

  await docRef.set(entry.toJson(), SetOptions(merge: true));
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
