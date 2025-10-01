// routine_model.dart

class Routine {
  final String docId; // Firestore 문서 ID
  final String title; // 루틴 제목
  final Map<String, String> days; // 요일별 시간 (예: {"월": "08:00", "수": "08:00"})
  final String userId; // 등록한 사용자 ID
  final DateTime createdAt; // 생성 시간

  Routine({
    required this.docId,
    required this.title,
    required this.days,
    required this.userId,
    required this.createdAt,
  });

  // Firestore에서 가져올 때 쓰는 함수
  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      docId: json['docId'] as String,
      title: json['title'] as String,
      days: Map<String, String>.from(json['days']),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Firestore에 저장할 때 쓰는 함수
  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'title': title,
      'days': days,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 복사(copyWith) 기능도 추가하면 좋음 (선택)
  Routine copyWith({
    String? docId,
    String? title,
    Map<String, String>? days,
    String? userId,
    DateTime? createdAt,
  }) {
    return Routine(
      docId: docId ?? this.docId,
      title: title ?? this.title,
      days: days ?? this.days,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
