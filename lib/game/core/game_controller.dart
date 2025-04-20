// game_controller.dart
import 'package:flutter/material.dart';
import '/chatdo/models/game_sync_data.dart';

class GameController {
  int _point = 0;
  int _level = 1;
  int _completedCount = 0;
  int _streak = 0;
  String? _lastTodoText;
  bool _hasLeveledUp = false;
  bool _completedToday = false;

  void sync(GameSyncData data) {
    _point = data.point;
    _level = data.level;
    _completedCount = data.completedCount;
    _streak = data.consecutiveDays;
    _lastTodoText = data.lastTodoText;
    _completedToday = data.completedToday;

    if (data.leveledUp) {
      _hasLeveledUp = true;
      triggerLevelUpAnimation();
    }

    if (data.completedToday) {
      playJordyReaction();
    }
  }

  void triggerLevelUpAnimation() {
    debugPrint('✨ 레벨업 애니메이션 발동');
    // TODO: Flame 애니메이션 실행 로직 연결
  }

  void playJordyReaction() {
    debugPrint('🧚 조르디 반응 연출: 오늘 할일 완료!');
    // TODO: 조르디 감정 반응 처리
  }

  // getter (필요시)
  int get point => _point;
  int get level => _level;
  int get completedCount => _completedCount;
  int get streak => _streak;
  String? get lastTodoText => _lastTodoText;
  bool get completedToday => _completedToday;
  bool get hasLeveledUp => _hasLeveledUp;
}
