class SunPmSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    return now.weekday == DateTime.sunday && now.hour >= 12 && now.hour < 20;
  }
}
