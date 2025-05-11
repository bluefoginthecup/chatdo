

class SatNightSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    return now.weekday == DateTime.saturday && now.hour >= 18 && now.hour < 24;
  }
}
