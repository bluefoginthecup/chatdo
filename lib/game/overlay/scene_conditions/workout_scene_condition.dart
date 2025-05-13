import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/chatdo/models/schedule_entry.dart';
import 'package:intl/intl.dart';

class WorkoutSceneCondition {
  static Future<bool> shouldShow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final formatter = DateFormat('yyyy-MM-dd');
    final yesterdayString = formatter.format(yesterday);

    final query = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('date', isGreaterThanOrEqualTo: yesterdayString)
        .where('mode', isEqualTo: 'done')
        .orderBy('date', descending: true)
        .get();

    for (final doc in query.docs) {
      final entry = ScheduleEntry.fromJson(doc.data());
      if (entry.tags.contains('운동')) {
        return true;
      }
    }
    return false;
  }
}
