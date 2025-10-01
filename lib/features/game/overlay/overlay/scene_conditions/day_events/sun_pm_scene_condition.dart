class SunPmSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    final result =
        now.weekday == DateTime.sunday && now.hour >= 12 && now.hour < 23;
    print('🧪 [SunPmScene] now=$now → $result');
    return result;
  }
}
