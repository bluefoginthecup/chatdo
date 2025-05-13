class MonNoonSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    final result = now.weekday == DateTime.monday && now.hour >= 12 && now.hour < 18;
    print('🧪 [MonNoonScene] now=$now → $result');
    return result;
  }
}