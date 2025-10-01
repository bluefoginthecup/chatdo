// =========================
// 5) Provider (ChangeNotifier)
// =========================
// lib/game/progress/progress_provider.dart
import 'package:flutter/foundation.dart';
import 'progress_models.dart';
import 'progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService service;
  ProgressTotals totals = const ProgressTotals();
  ProgressDelta lastDelta = const ProgressDelta(0, 0);
  bool isReady = false;

  ProgressProvider(this.service);

  Future<void> init() async {
    totals = await service.ensureLoaded();
    isReady = true;
    notifyListeners();
  }

  Future<void> award(RewardEvent ev) async {
    final (t, d) = await service.award(ev);
    totals = t;
    lastDelta = d;
    notifyListeners();
  }
}
