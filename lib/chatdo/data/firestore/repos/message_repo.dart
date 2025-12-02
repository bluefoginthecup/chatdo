// lib/chatdo/data/firestore/repos/message_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../paths.dart';
import '../../../models/message.dart';
import '../../../models/schedule_entry.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint
import 'package:hive/hive.dart';


// ─────────────────────────────────────────────────────────────
// ✅ 페이지 결과 DTO: 파일 최상위에 둬야 함 (클래스 안 X)
// ─────────────────────────────────────────────────────────────
class PageResult {
    final List<ScheduleEntry> entries;
    final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    final bool isEnd;
    PageResult({
      required this.entries,
      required this.lastDoc,
      required this.isEnd,
    });
  }



class MessageRepo {
  final UserStorePaths paths;

  MessageRepo(this.paths);

  // ─────────────────────────────────────────────
    // ✅ 공통: Hive 박스/중복 확인 헬퍼
    // ─────────────────────────────────────────────
    Future<Box<Message>> _openMsgBox() async {
        // 이미 열려 있으면 Hive.box()로 가져와도 됨
        if (Hive.isBoxOpen('messages')) return Hive.box<Message>('messages');
        return Hive.openBox<Message>('messages');
      }

    Future<bool> _existsInHive(Box<Message> box, String id) async {
        // 간단히 선형 검색 (데이터 많아지면 id->key 인덱싱 고려)
        for (final k in box.keys) {
          final m = box.get(k);
          if (m is Message && m.id == id) return true;
        }
        return false;
      }


  // 🔽🔽🔽 추가: Storage 헬퍼
  Future<void> _deleteStorageForEntry({
    required String uid,
    required String docId,
    required List<String> imagePaths,
    required List<String> imageUrls,
  }) async {
    final st = firebase_storage.FirebaseStorage.instance;


    // 1) 경로 기반 삭제 (신 스키마)
    final futures = <Future>[];
    for (final p in imagePaths) {
      futures.add(st.ref(p).delete().catchError((_) {}));
    }

    // 2) 경로가 비어있으면 폴더 스캔(listAll)로 삭제 시도
    if (imagePaths.isEmpty) {
      final dirRef = st.ref('users/$uid/chat_images/$docId');
      try {
        final result = await dirRef.listAll();
        for (final item in result.items) {
          futures.add(item.delete().catchError((_) {}));
        }
      } catch (_) {
        // 폴더가 없거나 권한 문제면 무시
      }
    }

    // 3) URL 기반 삭제 (구 스키마 폴백)
    for (final u in imageUrls) {
      futures.add(st.refFromURL(u).delete().catchError((_) {}));
    }

    await Future.wait(futures, eagerError: false);
  }

  // 🔽🔽🔽 추가: 엔트리 객체를 이미 갖고 있을 때
  Future<void> removeCascadeByEntry(String uid, ScheduleEntry e) async {
    if (e.docId == null) return;
    await _deleteStorageForEntry(
      uid: uid,
      docId: e.docId!,
      imagePaths: e.imagePaths,
      imageUrls: e.imageUrls ?? const [],
    );
    await paths.messages(uid).doc(e.docId!).delete();
  }

  // 🔽🔽🔽 추가: id만 있을 때(내부에서 한 번 읽고 지움)
  Future<void> removeCascade(String uid, String id) async {
    final doc = await paths.messages(uid).doc(id).get();
    final data = doc.data() ?? {};
    final imagePaths = List<String>.from(data['imagePaths'] ?? const []);
    final imageUrls = (data['imageUrls'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? const [];

    await _deleteStorageForEntry(
      uid: uid,
      docId: id,
      imagePaths: imagePaths,
      imageUrls: imageUrls,
    );
    await paths.messages(uid).doc(id).delete();
  }


  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String uid,
      String id) =>
      paths.messages(uid).doc(id).get();

  /// 새 문서 ID 미리 뽑고 싶을 때
  String newId(String uid) =>
      paths
          .messages(uid)
          .doc()
          .id;

  /// 일정 저장: 있으면 업데이트, 없으면 생성
  Future<void> upsertEntry(String uid, ScheduleEntry e) async {
    assert(e.docId != null && e.docId!.isNotEmpty, 'docId는 필수다');

    final doc = paths.messages(uid).doc(e.docId);

    // 1) 달력 키: 로컬 자정→UTC 자정으로 저장
    final localDay = DateTime(e.date.year, e.date.month, e.date.day);
    final utcMidnight = DateTime.utc(
        localDay.year, localDay.month, localDay.day);

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
    await doc.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
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
          ? Timestamp.fromDate(
          DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day))
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
        .set({...patch, 'uid': uid, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
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
  Future<List<ScheduleEntry>> fetchDayByType(String uid,
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

    final q3 = base.where('type', isEqualTo: type.name).where(
        'date', isEqualTo: ymd);
    final q4 = base.where('mode', isEqualTo: type.name).where(
        'date', isEqualTo: ymd);

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
  Future<void> postponeOneDay(String uid,
      String id,
      DateTime newDate, {
        String? originDateYmd,
      }) async {
    final doc = paths.messages(uid).doc(id);
    final utcMid = DateTime.utc(newDate.year, newDate.month, newDate.day);

    final patch = <String, dynamic>{
      'date': Timestamp.fromDate(utcMid),
      'timestamp': DateTime
          .now()
          .millisecondsSinceEpoch, // ✅ int millis로 통일
      'postponedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (originDateYmd != null) patch['originDate'] = originDateYmd;

    await doc.set(patch, SetOptions(merge: true));
  }

   // ─────────────────────────────────────────────────────────────
   // 🔥 Firestore 페이지네이션 (읽기 절감용)
   // ─────────────────────────────────────────────────────────────


  void _log(String msg) {
     if (kDebugMode) debugPrint('[MessageRepo] $msg'
    );

  }





  ScheduleEntry _docToEntry(QueryDocumentSnapshot<Map<String, dynamic>> d) {
     return ScheduleEntry.fromFirestore(d);
     }





  /// 최신 페이지 n개 (timestamp desc)


  Future<PageResult> fetchLatestPage(String uid, {int limit = 10}) async {
     final q = paths
     .messages(uid)
     .orderBy('timestamp', descending: true)
     .limit(limit);
     final snap = await q.get();
     _log('fetchLatestPage: fetched=${snap.docs.length}, fromCache=${snap.metadata.isFromCache}');
     if (snap.docs.isEmpty) {
     return PageResult(entries: const [], lastDoc: null, isEnd: true);
     }
     final entries = snap.docs.map(_docToEntry).toList();
     final last = snap.docs.last;
     return PageResult(entries: entries, lastDoc: last, isEnd: snap.docs.length < limit);

  }

    // ─────────────────────────────────────────────
    // 🔥 수동 동기화: 과거 배치(olderThanTs 기준) → Hive에 저장
    //    - UI는 Hive만 읽고, 이미지는 다운로드하지 않음(메타만 저장)
    //    - 반환: 이번에 추가된 문서 수
    // ─────────────────────────────────────────────
    Future<int> syncOlderToHive({
      required String uid,
      required int olderThanTs,
      int limit = 50,
    }) async {
    final col = paths.messages(uid);
    final q = col
        .orderBy('timestamp', descending: true)
        .where('timestamp', isLessThan: olderThanTs)
        .limit(limit);

    final qs = await q.get();
    if (qs.docs.isEmpty) return 0;

    final box = await _openMsgBox();
    int inserted = 0;

    for (final d in qs.docs) {
      final data = d.data();
      final id = d.id;
      if (await _existsInHive(box, id)) continue;

      final text = (data['text'] ?? data['content'] ?? '').toString();
      final tsAny = data['date'];
      final date = tsAny is Timestamp
          ? tsAny.toDate()
          : (DateTime.tryParse(tsAny?.toString() ?? '') ?? DateTime.now());
      final typeStr = (data['type'] ?? data['mode'] ?? 'todo').toString();
      final img = data['imageUrl'] as String?;
      final imgs = (data['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final tags = (data['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final ts = data['timestamp'] is int
          ? data['timestamp'] as int
          : (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch);

      await box.add(Message(
        id: id,
        text: text,
        type: typeStr,
        date: DateFormat('yyyy-MM-dd').format(date),
        timestamp: ts,
        imageUrl: img,
        imageUrls: imgs,
        tags: tags,
      ));
      inserted++;
    }

    _log('syncOlderToHive: inserted=$inserted (limit=$limit, olderThan=$olderThanTs)');
    return inserted;
  }

  // ─────────────────────────────────────────────
  // (옵션) 최신 배치 한 번 동기화 → Hive
  //   - 앱 첫 실행 시 최신 n개만 당겨둘 때 사용
  // ─────────────────────────────────────────────
  Future<int> syncLatestToHive({
    required String uid,
    int limit = 50,
  }) async {
    final col = paths.messages(uid);
    final q = col.orderBy('timestamp', descending: true).limit(limit);
    final qs = await q.get();
    if (qs.docs.isEmpty) return 0;

    final box = await _openMsgBox();
    int inserted = 0;
    for (final d in qs.docs) {
      final data = d.data();
      final id = d.id;
      if (await _existsInHive(box, id)) continue;

      final text = (data['text'] ?? data['content'] ?? '').toString();
      final tsAny = data['date'];
      final date = tsAny is Timestamp
          ? tsAny.toDate()
          : (DateTime.tryParse(tsAny?.toString() ?? '') ?? DateTime.now());
      final typeStr = (data['type'] ?? data['mode'] ?? 'todo').toString();
      final img = data['imageUrl'] as String?;
      final imgs = (data['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final tags = (data['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final ts = data['timestamp'] is int
          ? data['timestamp'] as int
          : (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch);

      await box.add(Message(
        id: id,
        text: text,
        type: typeStr,
        date: DateFormat('yyyy-MM-dd').format(date),
        timestamp: ts,
        imageUrl: img,
        imageUrls: imgs,
        tags: tags,
      ));
      inserted++;
    }
    _log('syncLatestToHive: inserted=$inserted (limit=$limit)');
    return inserted;
  }




  /// 다음 페이지 n개 (마지막 문서 스냅샷 기준)


  Future<PageResult> fetchNextPage

  (



  String uid, {
   required DocumentSnapshot<Map<String, dynamic>> lastDoc,
   int limit = 10,
   }) async {
   final q = paths
   .messages(uid)
   .orderBy('timestamp', descending: true)
   .startAfterDocument(lastDoc)
   .limit(limit);
   final snap = await q.get();
   _log('fetchNextPage: fetched=${snap.docs.length}, fromCache=${snap.metadata.isFromCache}');
   if (snap.docs.isEmpty) {
   return PageResult(entries: const [], lastDoc: lastDoc, isEnd: true);
   }
   final entries = snap.docs.map(_docToEntry).toList();
   final newLast = snap.docs.last;
   return PageResult(entries: entries, lastDoc: newLast, isEnd: snap.docs.length < limit);
   }
}