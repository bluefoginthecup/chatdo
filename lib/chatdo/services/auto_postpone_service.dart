// lib/chatdo/services/auto_postpone_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart'; // ← Message 모델 경로 확인

class AutoPostponeService {
  static const _pEnabled = 'auto_postpone_enabled';
  static const _pLastRun = 'auto_postpone_last_run'; // 'yyyy-MM-dd'

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 앱 시작 시 등에서 호출: 설정 켜져 있으면 하루 1회만 실행
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

  /// 메뉴에서 “지금 실행” 눌렀을 때
  static Future<int> runNow() async {
    final n = await _runCore();
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_pLastRun, todayStr);
    return n;
  }

  /// 핵심 로직: 과거의 todo를 전부 오늘로 미룸 (Hive + Firestore 동시 반영)
  static Future<int> _runCore() async {
    final box = Hive.box<Message>('messages'); // ✅ 채팅이 보는 박스
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = _day(DateTime.now());
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    int patched = 0;

    // Hive 메시지 전수 검사
    for (final key in box.keys) {
      final m = box.get(key);
      if (m is! Message) continue;
      if (m.type != 'todo') continue;             // 완료건은 대상 아님
      if (m.date.isEmpty) continue;

      DateTime d;
      try {
        d = DateTime.parse(m.date);               // 'yyyy-MM-dd' 전제
      } catch (_) {
        continue;
      }

      if (_day(d).isBefore(today)) {
        // 1) Hive 먼저 갱신 → 채팅 즉시 반영
        final updated = Message(
          id: m.id,
          text: m.text,
          type: m.type,                   // 그대로 'todo'
          date: todayStr,                 // ✅ 핵심: 오늘로
          timestamp: DateTime.now().millisecondsSinceEpoch, // 정렬 보정
          imageUrl: m.imageUrl,
          imageUrls: m.imageUrls,
          tags: m.tags,
        );
        await box.put(key, updated);
        patched++;

        // 2) 파이어베이스도 같은 문서 갱신 → 캘린더도 바로 반영
        if (uid != null && m.id.isNotEmpty) {
          final ref = FirebaseFirestore.instance
              .collection('messages')
              .doc(uid)
              .collection('logs')
              .doc(m.id);

          await ref.set({
            'date': todayStr,                   // ✅ 캘린더 쿼리용 포맷
            // 'mode'는 그대로 todo라면 생략 가능. 혹시 바뀔 여지 있으면 명시:
            // 'mode': 'todo',
            'timestamp': Timestamp.now(),       // 선택: 정렬/최근반영
          }, SetOptions(merge: true));
        }
      }
    }

    return patched;
  }
}
