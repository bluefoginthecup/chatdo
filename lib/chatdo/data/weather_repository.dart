import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/weather_service.dart';

class WeatherRepository {
  final WeatherService _service = WeatherService();

  static const _weatherTextKey = 'weather_text';
  static const _weatherBgKey = 'weather_bg';
  static const _weatherDateKey = 'weather_date';

  Future<(String text, String bgImage)> getTodayWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final lastFetched = prefs.getString(_weatherDateKey);

    if (lastFetched == today) {
      final cachedText = prefs.getString(_weatherTextKey) ?? '날씨 정보를 불러올 수 없어요.';
      final cachedBg = prefs.getString(_weatherBgKey) ?? 'background.png';
      return (cachedText, cachedBg);
    }

    final data = await _service.fetchWeatherFromCurrentLocation();

    if (data['weather'] == null || data['main'] == null) {
      throw Exception('날씨 데이터가 비어 있습니다: $data');
    }

    final condition = data['weather'][0]['main'];


    final maxTemp = data['main']['temp_max'].round();
    final minTemp = data['main']['temp_min'].round();

    final summary = _simpleDescription(condition);
    final text = '오늘은 ${summary} 최고 ${maxTemp}도 / 최저 ${minTemp}도예요.';
    final bgImage = _mapWeatherToBg(condition);

    // 캐싱
    await prefs.setString(_weatherTextKey, text);
    await prefs.setString(_weatherBgKey, bgImage);
    await prefs.setString(_weatherDateKey, today);

    return (text, bgImage);
  }

  String _simpleDescription(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '맑고';
      case 'rain':
      case 'drizzle':
      return '비가 오고';
      case 'thunderstorm':
        return '천둥번개가 치고';
      case 'clouds':
        return '흐리고';
      case 'snow':
        return '눈이 오고';
      default:
        return '나쁘지 않은 날씨이고';
    }
  }

  String _mapWeatherToBg(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'room_bg_sunny.png';
      case 'rain':
      case 'drizzle':
      return 'room_bg_rainy.png';
      case 'thunderstorm':
        return 'room_bg_thunderbolt.png';
      case 'clouds':
        return 'room_bg_cloudy.png';
      case 'snow':
        return 'room_bg_snowy.png';
      default:
        return 'background.png';
    }
  }
}
