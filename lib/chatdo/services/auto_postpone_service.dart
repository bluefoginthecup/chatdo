import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart'; // Message(id, text, type, date(String 'yyyy-MM-dd'), timestamp(int), ...)

class AutoPostponeService {
  static const _pEnabled = 'auto_postpone_enabled';
  static const _pLastRun = 'auto_postpone_last_run'; // 'yyyy-MM-dd'

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 앱 진입/복귀 때 호출: 설정 켜져 있으면 **하루 1번만** 실행
  static Future<int> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_pEnabled) ?? false;
    if (!enabled) return 0;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString(_pLastRun) == todayStr) return 0;

    final n = await _runCore();
    await prefs.setString(_pLastRun, todayStr);
    return n;
  }

  /// 메뉴에서 수동 실행
  static Future<int> runNow() async {
    final n = await _runCore();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_pLastRun, todayStr);
    return n;
  }

  /// 핵심: **과거의 todo 전부**를 오늘로 미룸.
  /// - Hive: date만 오늘로, **timestamp는 건드리지 않음**(최초 등록 시각 보존)
  /// - Firestore: date 갱신 + originDate(처음 지정일) 없으면 **한 번만** 세팅
  static Future<int> _runCore() async {
    final box = Hive.box<Message>('messages');
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final today = _day(DateTime.now());
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    int patched = 0;

    for (final key in box.keys) {
      final m = box.get(key);
      if (m is! Message) continue;
      if (m.type != 'todo') continue;
      if ((m.date).isEmpty) continue;

      DateTime d;
      try {
        d = DateTime.parse(m.date); // 'yyyy-MM-dd'
      } catch (_) {
        continue;
      }

      if (_day(d).isBefore(today)) {
        // 1) Hive 먼저 갱신: timestamp는 **그대로** 둔다
        final updated = Message(
          id: m.id,
          text: m.text,
          type: m.type,              // 'todo'
          date: todayStr,            // 오늘로 미룸
          timestamp: m.timestamp,    // ✅ 최초 등록 시각 보존
          imageUrl: m.imageUrl,
          imageUrls: m.imageUrls,
          tags: m.tags,
        );
        await box.put(key, updated);
        patched++;

        // 2) Firestore도 반영 (캘린더 동기)
        if (uid != null && m.id.isNotEmpty) {
          final ref = FirebaseFirestore.instance
              .collection('messages').doc(uid)
              .collection('logs').doc(m.id);

          // originDate 유무 확인
          String? originDate;
          try {
            final snap = await ref.get();
            final data = snap.data();
            if (data != null && data['originDate'] is String) {
              originDate = data['originDate'] as String;
            }
          } catch (_) {}

          await ref.set({
            'date': todayStr,                                  // 현재 일정일
            if (originDate == null) 'originDate': m.date,      // ✅ 최초 한 번만 세팅
            'postponedCount': FieldValue.increment(1),          // 미룬 횟수
            'lastPostponedAt': FieldValue.serverTimestamp(),   // 마지막 미룸 시각
            // 'timestamp'는 건드리지 않음(최초 등록시각 보존)
          }, SetOptions(merge: true));
        }
      }
    }

    return patched;
  }
}
