// game_sync_data.dart
class GameSyncData {
  final int point;
  final int level;
  final int completedCount;
  final int consecutiveDays;
  final String? lastTodoText;
  final bool leveledUp;
  final bool completedToday;

  GameSyncData({
    required this.point,
    required this.level,
    required this.completedCount,
    required this.consecutiveDays,
    required this.lastTodoText,
    required this.leveledUp,
    required this.completedToday,
  });
}
