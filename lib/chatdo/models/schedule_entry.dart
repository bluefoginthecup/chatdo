enum ScheduleType { todo, done }

class ScheduleEntry {
  final DateTime date;
  final ScheduleType type;
  final String content;
  final DateTime createdAt;
  final String? docId; // ✅ Firestore 문서 ID 추가
  final String? imageUrl; // ✅ 이미지 메시지용 URL

  ScheduleEntry({
    required this.date,
    required this.type,
    required this.content,
    this.docId,
    DateTime? createdAt,
    this.imageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['mode'] == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: DateTime.parse(json['timestamp'] as String),
      docId: json['docId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static ScheduleEntry fromParsedEntry(DateTime date, ScheduleType type, String content) {
    return ScheduleEntry(date: date, type: type, content: content, createdAt: DateTime.now());
  }
}

extension ScheduleEntryJson on ScheduleEntry {
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'date': date.toIso8601String(),
      'timestamp': createdAt.toIso8601String(),
      'mode': type.name,
      'docId': docId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
