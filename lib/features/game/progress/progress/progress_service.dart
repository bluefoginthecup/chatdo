// =========================
// 4) 서비스 (룰 적용 + 합산)
// =========================
// lib/game/progress/progress_service.dart
import 'progress_models.dart';
import 'progress_repo.dart';
import 'progress_rules.dart';

class ProgressService {
  final ProgressRepo repo;
  ProgressTotals _cache = const ProgressTotals();
  bool _loaded = false;

  ProgressService(this.repo);

  Future<ProgressTotals> ensureLoaded() async {
    if (!_loaded) {
      _cache = await repo.load();
      _loaded = true;
    }
    return _cache;
  }

  Future<(ProgressTotals, ProgressDelta)> award(RewardEvent ev) async {
    await ensureLoaded();
    final delta = _deltaFor(ev);
    final next = _cache.copyWith(
      xp: _cache.xp + delta.xp,
      gold: _cache.gold + delta.gold,
    );
    _cache = next;
    await repo.save(next);
    return (next, delta);
  }

  ProgressDelta _deltaFor(RewardEvent ev) {
    switch (ev) {
      case RewardEvent.scheduleCreated:
        return ProgressDelta(ProgressRules.xpOnScheduleCreate,
            ProgressRules.goldOnScheduleCreate);
      case RewardEvent.scheduleCompleted:
        return ProgressDelta(ProgressRules.xpOnScheduleComplete,
            ProgressRules.goldOnScheduleComplete);
    }
  }
}
