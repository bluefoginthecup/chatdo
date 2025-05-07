import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 관련 클래스 (DocumentSnapshot, Timestamp)


enum ScheduleType { todo, done }

class ScheduleEntry {
  final DateTime date;
  final ScheduleType type;
  final String content;
  final DateTime createdAt;
  final String? docId;
  final String? imageUrl;
  final String? body;
  final Map<String, dynamic>? routineInfo;
  final List<String>? imageUrls;
  final List<String> tags;
  final DateTime timestamp;



  ScheduleEntry({
    required this.date,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.docId,
    this.imageUrl,
    this.body,
    this.routineInfo,
    this.imageUrls,
    this.tags = const [],
    required this.timestamp,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    // ✅ date 필드 안전하게 파싱
    final dynamic dateRaw = json['date'];
    DateTime parsedDate;

    if (dateRaw is Timestamp) {
      parsedDate = dateRaw.toDate();
    } else if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now(); // fallback
    }

    // ✅ timestamp도 안전하게 파싱
    final dynamic timestampRaw = json['timestamp'];
    DateTime createdAt;

    if (timestampRaw is Timestamp) {
      createdAt = timestampRaw.toDate();
    } else if (timestampRaw is String) {
      createdAt = DateTime.tryParse(timestampRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ScheduleEntry(
      content: json['content'] as String,
      date: parsedDate,
      type: json['mode'] == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: createdAt,
      // 이거 추가해줘야 함
      timestamp: createdAt,
      docId: json['docId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      body: json['body'] as String?,
      routineInfo: json['routineInfo'] as Map<String, dynamic>?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
  factory ScheduleEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawDate = data['date'];
    DateTime parsedDate;

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      throw Exception('Unknown date format');
    }

    // ✅ 여기서 먼저 createdAt 따로 선언
    final createdAt = (data['timestamp'] is Timestamp)
        ? (data['timestamp'] as Timestamp).toDate()
        : (data['timestamp'] is String)
        ? DateTime.parse(data['timestamp'])
        : DateTime.now();


    return ScheduleEntry(
      content: data['content'] ?? '',
      body: data.containsKey('body') ? data['body'] as String? ?? '' : '',


      date: parsedDate,
      type: data['mode'] == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: createdAt,
      timestamp: createdAt, // 혹은 위에서 새로 만든 timestamp 변수
      docId: data['docId'],
      imageUrl: data['imageUrl'],
      routineInfo: data['routineInfo'],
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>(),
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],


    );
  }


  static ScheduleEntry fromParsedEntry(DateTime date, ScheduleType type, String content) {
    final now = DateTime.now();
    return ScheduleEntry(
        date: date,
        type: type,
        content: content,
        createdAt: now,
      timestamp: now,);
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'date': date.toIso8601String(),
      'timestamp': createdAt.toIso8601String(),
      'mode': type.name,
      'docId': docId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (body != null) 'body': body,
      if (routineInfo != null) 'routineInfo': routineInfo,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }

  ScheduleEntry copyWith({
    DateTime? date,
    ScheduleType? type,
    String? content,
    DateTime? createdAt,
    String? docId,
    String? imageUrl,
    String? body,
    Map<String, dynamic>? routineInfo,
    List<String>? imageUrls,
    List<String>? tags,
    DateTime? timestamp,
  }) {
    return ScheduleEntry(
      date: date ?? this.date,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      docId: docId ?? this.docId,
      imageUrl: imageUrl ?? this.imageUrl,
      body: body ?? this.body,
      routineInfo: routineInfo ?? this.routineInfo,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
