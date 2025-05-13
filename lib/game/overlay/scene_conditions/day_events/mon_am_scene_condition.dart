
class MonAmSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    final result = now.weekday == DateTime.monday && now.hour >= 0 && now.hour < 12;
    print('🧪 [MonAmScene] now=$now → $result');
    return result;
  }
}
