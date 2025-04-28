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
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['mode'] == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: DateTime.parse(json['timestamp'] as String),
      docId: json['docId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      body: json['body'] as String?,
      routineInfo: json['routineInfo'] as Map<String, dynamic>?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>(),


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

    return ScheduleEntry(
      content: data['content'] ?? '',
      body: data['body'],
      date: parsedDate,
      type: data['mode'] == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is String)
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      docId: data['docId'],
      imageUrl: data['imageUrl'],
      routineInfo: data['routineInfo'],
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>(),

    );
  }


  static ScheduleEntry fromParsedEntry(DateTime date, ScheduleType type, String content) {
    return ScheduleEntry(date: date, type: type, content: content, createdAt: DateTime.now());
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
    );
  }
}
