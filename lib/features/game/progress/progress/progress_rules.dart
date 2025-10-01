// =========================
// 1) 룰 정의 (외부화 전, 하드코딩)
// =========================
// lib/game/progress/progress_rules.dart
class ProgressRules {
  static const int xpOnScheduleCreate = 10; // 일정 생성
  static const int goldOnScheduleCreate = 3;
  static const int xpOnScheduleComplete = 100; // 일정 완료(할일→한일)
  static const int goldOnScheduleComplete = 20;
}
