class TueAmSceneCondition {
  static Future<bool> shouldShow() async {
    final now = DateTime.now();
    final result = now.weekday == DateTime.tuesday && now.hour >= 0 && now.hour < 12;

    print('🧪 [TueAmScene] now=$now → $result');
    return result;
  }
}
