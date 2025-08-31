// lib/chatdo/data/firestore/repos/message_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../paths.dart';
import '../../../models/message.dart';
import '../../../models/schedule_entry.dart';
import 'package:intl/intl.dart';

class MessageRepo {
  final UserStorePaths paths;
  MessageRepo(this.paths);

  /// 새 문서 ID 미리 뽑고 싶을 때
  String newId(String uid) => paths.messages(uid).doc().id;

  /// 일정 저장: 있으면 업데이트, 없으면 생성
  Future<void> upsertEntry(String uid, ScheduleEntry e) async {
    assert(e.docId != null && e.docId!.isNotEmpty, 'docId는 필수다');

    final doc = paths.messages(uid).doc(e.docId);

    // 1) 달력 키: 로컬 자정→UTC 자정으로 저장
    final localDay = DateTime(e.date.year, e.date.month, e.date.day);
    final utcMidnight = DateTime.utc(localDay.year, localDay.month, localDay.day);

    // 2) 모델 → 맵(기본값), 날짜만 UTC 자정으로 교체
    final base = e.copyWith(date: utcMidnight).toFirestoreMap();

    // 3) 최종 저장용 데이터
    final data = {
      ...base,
      'uid': uid,
      // createdAt은 최초만, updatedAt은 항상 갱신
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // createdAt 최초 세팅(덮어쓰기 방지)
    await doc.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    // 나머지 병합
    await doc.set(data, SetOptions(merge: true));
  }

  /// 실시간 메시지(=일정) 스트림
  Stream<List<Map<String, dynamic>>> watch(String uid) {
    return paths
        .messages(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Hive Message → Firestore 저장(초기 이관/오프라인 업로드용)
  Future<String> addFromHive(String uid, Message m) async {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(m.date);
    } catch (_) {}

    final data = <String, dynamic>{
      'uid': uid,
      'text': m.text,
      'type': m.type, // 'todo' | 'done'
      'date': parsedDate != null
          ? Timestamp.fromDate(DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day))
          : null,
      'timestamp': m.timestamp, // ✅ int millis로 일관
      'imageUrl': m.imageUrl,
      'imageUrls': m.imageUrls ?? const <String>[],
      'tags': m.tags ?? const <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final ref = await paths.messages(uid).add(data);
    return ref.id;
  }

  /// 부분 업데이트(Map 패치)
  Future<void> updateMap(String uid, String id, Map<String, dynamic> patch) {
    return paths
        .messages(uid)
        .doc(id)
        .set({...patch, 'uid': uid, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> remove(String uid, String id) {
    return paths.messages(uid).doc(id).delete();
  }

  /// 달력: 월 범위 조회
  Future<List<ScheduleEntry>> fetchMonth(String uid, DateTime monthDate) async {
    final first = DateTime.utc(monthDate.year, monthDate.month, 1);
    final next = DateTime.utc(monthDate.year, monthDate.month + 1, 1);

    final snap = await paths
        .messages(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(first))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .orderBy('date')
        .get();

    return snap.docs.map(ScheduleEntry.fromFirestore).toList();
  }

  /// 달력: 하루 범위 조회
  Future<List<ScheduleEntry>> fetchDay(String uid, DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snap = await paths
        .messages(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snap.docs.map(ScheduleEntry.fromFirestore).toList();
  }

  /// 하루 + 타입(태그 옵션)
  Future<List<ScheduleEntry>> fetchDayByType(
      String uid,
      DateTime day,
      ScheduleType type, {
        String? tag,
      }) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final ymd = DateFormat('yyyy-MM-dd').format(day);

    Query<Map<String, dynamic>> base = paths.messages(uid);
    if (tag != null && tag.isNotEmpty) {
      base = base.where('tags', arrayContains: tag);
    }

    final q1 = base
        .where('type', isEqualTo: type.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    // 2) 구 스키마A: mode + Timestamp 범위
    final q2 = base
        .where('mode', isEqualTo: type.name) // 구 스키마 호환
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    final q3 = base.where('type', isEqualTo: type.name).where('date', isEqualTo: ymd);
    final q4 = base.where('mode', isEqualTo: type.name).where('date', isEqualTo: ymd);

    final snaps = await Future.wait([q1.get(), q2.get(), q3.get(), q4.get()]);

    final seen = <String>{};
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final s in snaps) {
      for (final d in s.docs) {
        if (seen.add(d.id)) docs.add(d);
      }
    }
    return docs.map(ScheduleEntry.fromFirestore).toList();
  }

  /// 하루 미루기
  Future<void> postponeOneDay(
      String uid,
      String id,
      DateTime newDate, {
        String? originDateYmd,
      }) async {
    final doc = paths.messages(uid).doc(id);
    final utcMid = DateTime.utc(newDate.year, newDate.month, newDate.day);

    final patch = <String, dynamic>{
      'date': Timestamp.fromDate(utcMid),
      'timestamp': DateTime.now().millisecondsSinceEpoch, // ✅ int millis로 통일
      'postponedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (originDateYmd != null) patch['originDate'] = originDateYmd;

    await doc.set(patch, SetOptions(merge: true));
  }
}
