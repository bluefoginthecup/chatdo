enum ScheduleType { todo, done }

class ScheduleEntry {
  final DateTime date;
  final ScheduleType type;
  final String content;
  final DateTime createdAt;
  final String? docId;
  final String? imageUrl;
  final String? body;

  ScheduleEntry({
    required this.date,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.docId,
    this.imageUrl,
    this.body,
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
  }) {
    return ScheduleEntry(
      date: date ?? this.date,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      docId: docId ?? this.docId,
      imageUrl: imageUrl ?? this.imageUrl,
      body: body ?? this.body,
    );
  }
}
