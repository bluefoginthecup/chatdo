// scene_conditions.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatdo/chatdo/models/schedule_entry.dart';
import 'package:intl/intl.dart';


class SceneConditions {
  static Future<bool> shouldShowSickScene() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final formatter = DateFormat('yyyy-MM-dd');
    final twoDaysAgoString = formatter.format(twoDaysAgo);

    final query = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('date', isGreaterThanOrEqualTo: twoDaysAgoString)
        .where('mode', isEqualTo: 'done')
        .orderBy('date', descending: true)
        .get();

    for (final doc in query.docs) {
      final entry = ScheduleEntry.fromJson(doc.data());
      if (entry.content.contains("운동")) {
        return false;
      }
    }
    return true;
  }
}
