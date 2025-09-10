// 2) 모델
// =========================
// lib/game/progress/progress_models.dart
class ProgressTotals {
  final int xp;
  final int gold;
  const ProgressTotals({this.xp = 0, this.gold = 0});


  ProgressTotals copyWith({int? xp, int? gold}) =>
      ProgressTotals(xp: xp ?? this.xp, gold: gold ?? this.gold);


  Map<String, dynamic> toMap() => {"xp": xp, "gold": gold};
  factory ProgressTotals.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const ProgressTotals();
    return ProgressTotals(xp: (m["xp"] ?? 0) as int, gold: (m["gold"] ?? 0) as int);
  }
}


class ProgressDelta { // 보상 표시용
  final int xp;
  final int gold;
  const ProgressDelta(this.xp, this.gold);
  bool get isZero => xp == 0 && gold == 0;
}


enum RewardEvent { scheduleCreated, scheduleCompleted }