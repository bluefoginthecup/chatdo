// lib/chatdo/data/firestore/repos/message_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../paths.dart';
import '../../../models/message.dart';           // Hive 로컬 모델(추가/업데이트 때 참조)
import '../../../models/schedule_entry.dart';  // 캘린더 변환용
import 'package:intl/intl.dart';

class MessageRepo {
  final UserStorePaths paths;
  MessageRepo(this.paths);

  /// 실시간 메시지 스트림 (Map 기반)
  Stream<List<Map<String, dynamic>>> watch(String uid) {
    return paths.messages(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Hive Message -> Firestore 저장 (createdAt는 serverTimestamp)
  Future<String> addFromHive(String uid, Message m) async {
    DateTime? parsedDate;
    try { parsedDate = DateTime.parse(m.date); } catch (_) {}

    final data = <String, dynamic>{
      'uid': uid,
      'text': m.text,
      'type': m.type, // 'todo' | 'done' 등
      'date': parsedDate != null
          ? Timestamp.fromDate(DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day))
          : null,
      'timestamp': m.timestamp, // 정렬 참고용 int
      'imageUrl': m.imageUrl,
      'imageUrls': m.imageUrls ?? const <String>[],
      'tags': m.tags ?? const <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = await paths.messages(uid).add(data);
    return ref.id;
  }

  /// 부분 업데이트(Map 패치)
  Future<void> updateMap(String uid, String id, Map<String, dynamic> patch) {
    return paths.messages(uid)
        .doc(id)
        .set({...patch, 'uid': uid}, SetOptions(merge: true));
  }

  Future<void> remove(String uid, String id) {
    return paths.messages(uid).doc(id).delete();
  }

  /// 달력: 월 범위 조회 -> ScheduleEntry 리스트
  Future<List<ScheduleEntry>> fetchMonth(String uid, DateTime monthDate) async {
    final first = DateTime.utc(monthDate.year, monthDate.month, 1);
    final next  = DateTime.utc(monthDate.year, monthDate.month + 1, 1);

    final snap = await paths.messages(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(first))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .orderBy('date')
        .get();

    return snap.docs.map((d) => ScheduleEntry.fromFirestore(d)).toList();
  }

  /// 달력: 하루 범위 조회 -> ScheduleEntry 리스트
  Future<List<ScheduleEntry>> fetchDay(String uid, DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end   = start.add(const Duration(days: 1));

    final snap = await paths.messages(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snap.docs.map((d) => ScheduleEntry.fromFirestore(d)).toList();
  }

  Future<List<ScheduleEntry>> fetchDayByType(
      String uid,
      DateTime day,
      ScheduleType type, {
        String? tag,
      }) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end   = start.add(const Duration(days: 1));
    final ymd   = DateFormat('yyyy-MM-dd').format(day);

    Query<Map<String, dynamic>> base = paths.messages(uid);
    if (tag != null && tag.isNotEmpty) {
      base = base.where('tags', arrayContains: tag);
    }

    // 1) 최신 스키마: type + Timestamp 범위
    final q1 = base
        .where('type', isEqualTo: type.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    // 2) 구 스키마A: mode + Timestamp 범위
    final q2 = base
        .where('mode', isEqualTo: type.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    // 3) 구 스키마B: type + 문자열 날짜
    final q3 = base
        .where('type', isEqualTo: type.name)
        .where('date', isEqualTo: ymd);

    // 4) 구 스키마C: mode + 문자열 날짜
    final q4 = base
        .where('mode', isEqualTo: type.name)
        .where('date', isEqualTo: ymd);

    // 병렬 실행
    final snaps = await Future.wait([q1.get(), q2.get(), q3.get(), q4.get()]);

    // 합치고 중복 제거
    final seen = <String>{};
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final s in snaps) {
      for (final d in s.docs) {
        if (seen.add(d.id)) docs.add(d);
      }
    }

    // 변환
    return docs.map((d) => ScheduleEntry.fromFirestore(d)).toList();
  }

  // message_repo.dart 안
  Future<void> postponeOneDay(
      String uid,
      String id,
      DateTime newDate, {
        String? originDateYmd,
      }) async {
    final doc = paths.messages(uid).doc(id);
    if (originDateYmd != null) {
      await doc.set({'originDate': originDateYmd}, SetOptions(merge: true));
    }
    await doc.update({
      'date': Timestamp.fromDate(DateTime.utc(newDate.year, newDate.month, newDate.day)),
      'timestamp': FieldValue.serverTimestamp(),
      'postponedCount': FieldValue.increment(1),
    });
  }



}
