import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 관련 클래스 (DocumentSnapshot, Timestamp)
import 'package:intl/intl.dart';

enum ScheduleType { todo, done }

class ScheduleEntry {
  final DateTime date;                         // 일정 날짜 (UTC 자정 권장)
  final ScheduleType type;                    // todo | done
  final String content;                       // 본문 (새 스키마: text)
  final DateTime createdAt;                   // 생성 시각
  final String? docId;// 문서 ID
  final List<String> imagePaths;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? body;
  final Map<String, dynamic>? routineInfo;
  final List<String> tags;
  final DateTime timestamp;                   // 업데이트/정렬 기준 (updatedAt 성격)
  final bool isFixedDate;
  final int postponedCount;
  final bool isSyncedWithFirebase;
  final String? originDate;                   // 'yyyy-MM-dd' (optional, Firestore 전용일 수도)

  ScheduleEntry({
    required this.date,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.docId,
    this.imagePaths = const [],
    this.imageUrl,
    this.body,
    this.routineInfo,
    this.imageUrls,
    this.tags = const [],
    required this.timestamp,
    this.isFixedDate = false,
    this.postponedCount = 0,
    this.isSyncedWithFirebase = true,
    this.originDate,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 구/신 스키마 겸용 JSON 파서
  /// - text/type/date(Timestamp)  ← 신
  /// - content/mode/date(String)  ← 구
  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    // date
    final rawDate = json['date'];
    final DateTime parsedDate = switch (rawDate) {
      Timestamp t => t.toDate(),
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    // createdAt/timestamp (폴백: timestamp → createdAt → updatedAt → now)
    DateTime parseDT(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final createdAt = parseDT(json['timestamp'] ?? json['createdAt'] ?? json['updatedAt']);
    final typeStr = (json['type'] ?? json['mode'] ?? 'todo').toString();

    return ScheduleEntry(
      content: (json['text'] ?? json['content'] ?? '').toString(),
      date: parsedDate,
      type: typeStr == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: createdAt,
      timestamp: parseDT(json['timestamp'] ?? createdAt),
      docId: json['docId'] as String?,
      imagePaths: (json['imagePaths'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      imageUrl: json['imageUrl'] as String?,
      body: json['body'] as String?,
      routineInfo: (json['routineInfo'] as Map?)?.cast<String, dynamic>(),
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isFixedDate: (json['isFixedDate'] as bool?) ?? false,
      postponedCount: (json['postponedCount'] as int?) ?? 0,
      isSyncedWithFirebase: (json['isSyncedWithFirebase'] as bool?) ?? true,
      originDate: json['originDate'] as String?,
    );


  }

  /// Firestore 문서 파서 (구/신 스키마 겸용)
  factory ScheduleEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};

    // date
    final rawDate = data['date'];
    final DateTime parsedDate = switch (rawDate) {
      Timestamp t => t.toDate(),
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    // createdAt/timestamp (폴백 동일)
    DateTime parseDT(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final createdAt = parseDT(data['timestamp'] ?? data['createdAt'] ?? data['updatedAt']);
    final typeStr = (data['type'] ?? data['mode'] ?? 'todo').toString();

    return ScheduleEntry(
      content: (data['text'] ?? data['content'] ?? '').toString(),
      body: data.containsKey('body') ? (data['body'] as String?) ?? '' : '',
      date: parsedDate,
      type: typeStr == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: createdAt,
      timestamp: parseDT(data['timestamp'] ?? createdAt),
      docId: doc.id,
      imagePaths: List<String>.from(data['imagePaths'] ?? const []),
      imageUrl: data['imageUrl'] as String?,
      routineInfo: (data['routineInfo'] as Map?)?.cast<String, dynamic>(),
      imageUrls: (data['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isFixedDate: (data['isFixedDate'] as bool?) ?? false,
      postponedCount: (data['postponedCount'] as int?) ?? 0,
      isSyncedWithFirebase: (data['isSyncedWithFirebase'] as bool?) ?? true,
      originDate: data['originDate'] as String?,
    );
  }

  /// Firestore 저장용(새 스키마 전용) 맵
  /// - 호출부에서 'uid'는 꼭 채워서 set/update 하라.
  Map<String, dynamic> toFirestoreMap() {
    final utcDay = DateTime.utc(date.year, date.month, date.day);
    return {
      'docId': docId,
      'text': content,
      'type': type.name,
      'date': Timestamp.fromDate(utcDay),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(timestamp),
      'tags': tags,
      'imagePaths': imagePaths,
      if (imageUrl != null) 'imageUrl': imageUrl,         // 과도기 호환
      if (imageUrls != null) 'imageUrls': imageUrls,      // 과도기 호환
      if (body != null) 'body': body,
      if (routineInfo != null) 'routineInfo': routineInfo,
      if (originDate != null) 'originDate': originDate,
      'isFixedDate': isFixedDate,
      'postponedCount': postponedCount,
      'isSyncedWithFirebase': isSyncedWithFirebase,
    };
  }

  /// 로컬/백업용 구-스키마 JSON
  /// (서버 저장엔 toFirestoreMap() 권장)
  Map<String, dynamic> toJson() {
    final ymd = DateFormat('yyyy-MM-dd').format(date);
    return {
      'content': content,
      'date': ymd,
      'timestamp': createdAt.toIso8601String(),
      'mode': type.name,
      'docId': docId,
      'isFixedDate': isFixedDate,
      'postponedCount': postponedCount,
      'isSyncedWithFirebase': isSyncedWithFirebase,
      if (imagePaths.isNotEmpty) 'imagePaths': imagePaths,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (body != null) 'body': body,
      if (routineInfo != null) 'routineInfo': routineInfo,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (tags.isNotEmpty) 'tags': tags,
      if (originDate != null) 'originDate': originDate,
    };
  }

  /// 편의 게터
  String? get id => docId;

  /// 파서용 헬퍼
  static ScheduleEntry fromParsedEntry(DateTime date, ScheduleType type, String content) {
    final now = DateTime.now();
    return ScheduleEntry(
      date: date,
      type: type,
      content: content,
      createdAt: now,
      timestamp: now,
    );
  }

  ScheduleEntry copyWith({
    DateTime? date,
    ScheduleType? type,
    String? content,
    DateTime? createdAt,
    String? docId,
    List<String>? imagePaths,
    String? imageUrl,
    String? body,
    Map<String, dynamic>? routineInfo,
    List<String>? imageUrls,
    List<String>? tags,
    DateTime? timestamp,
    bool? isFixedDate,
    int? postponedCount,
    bool? isSyncedWithFirebase,
    String? originDate,
  }) {
    return ScheduleEntry(
      date: date ?? this.date,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      docId: docId ?? this.docId,
      imagePaths: imagePaths ?? this.imagePaths,
      imageUrl: imageUrl ?? this.imageUrl,
      body: body ?? this.body,
      routineInfo: routineInfo ?? this.routineInfo,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      isFixedDate: isFixedDate ?? this.isFixedDate,
      postponedCount: postponedCount ?? this.postponedCount,
      isSyncedWithFirebase: isSyncedWithFirebase ?? this.isSyncedWithFirebase,
      originDate: originDate ?? this.originDate,
    );
  }
}
