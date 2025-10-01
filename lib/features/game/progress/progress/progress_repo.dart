// =========================
// 3) 저장소 (로컬 우선, Hive 없어도 SharedPreferences 대체 가능)
// =========================
// lib/game/progress/progress_repo.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_models.dart';

class ProgressRepo {
  static const _kKey = 'progress_totals_v1';

  Future<ProgressTotals> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    if (raw == null) return const ProgressTotals();
    return ProgressTotals.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ProgressTotals totals) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, jsonEncode(totals.toMap()));
  }
}
