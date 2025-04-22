enum ScheduleType { todo, done }

class ScheduleEntry {
  final DateTime date;
  final ScheduleType type;
  final String content;
  final DateTime createdAt;
  final String? docId; // ✅ Firestore 문서 ID 추가

  ScheduleEntry({
    required this.date,
    required this.type,
    required this.content,
    this.docId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 파싱 결과를 ScheduleEntry로 바로 반환하도록 수정
  static ScheduleEntry fromParsedEntry(DateTime date, ScheduleType type, String content) {
    return ScheduleEntry(date: date, type: type, content: content, createdAt: DateTime.now());
  }
}