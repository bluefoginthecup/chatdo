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

  void addPoints(int value) {
    _point += value;
    print('🎯 포인트 추가: $value → 총 $_point');
    _checkLevelUp();
  }

  void subtractPoints(int value) {
    _point = (_point - value).clamp(0, _point);
    print('🔻 포인트 감소: $value → 총 $_point');
  }

  void _checkLevelUp() {
    while (_point >= _pointsToLevelUp(_level)) {
      _point -= _pointsToLevelUp(_level);
      _level++;
      print('🚀 레벨업! 현재 레벨: $_level');
    }
  }

  int _pointsToLevelUp(int currentLevel) {
    return 300 + (currentLevel - 1) * 50;
  }

  void triggerLevelUpAnimation() {
    debugPrint('✨ 레벨업 애니메이션 발동');
  }

  void playJordyReaction() {
    debugPrint('🧚 조르디 반응 연출: 오늘 할일 완료!');
  }

  // getter
  int get point => _point;
  int get level => _level;
  int get completedCount => _completedCount;
  int get streak => _streak;
  String? get lastTodoText => _lastTodoText;
  bool get completedToday => _completedToday;
  bool get hasLeveledUp => _hasLeveledUp;
}
