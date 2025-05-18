import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '/chatdo/services/weather_service.dart';


class WeatherRepository {
  final WeatherService _service = WeatherService();
  Map<String, dynamic>? _cachedWeather;

  Future<Map<String, dynamic>> _getWeather() async {
    if (_cachedWeather != null) return _cachedWeather!;
    _cachedWeather = await _service.fetchWeatherFromCurrentLocation();
    return _cachedWeather!;
  }


  /// 🔹 배경 + 설명 반환
  Future<(String text, String bgImagePath)> getTodayWeather() async {
    final weather = await _getWeather(); // 여기서 한 번만 호출됨
    final description = weather['description'] ?? 'clear';
    final bgImagePath = _getBackgroundPath(description);
    final text = '오늘 날씨는 $description입니다.';
    return (text, bgImagePath);
  }
  /// 🔹 설명만 따로 반환
  Future<String> getTodayWeatherDescription() async {
    final weather = await _getWeather(); // 동일한 데이터를 공유
    return weather['description'] ?? 'clear';
  }
  String _getBackgroundPath(String description) {
    if (description.contains('rain')) return 'background_farm_rainy.png';
    if (description.contains('snow')) return 'background_farm_snowy.png';
    if (description.contains('cloud')) return 'background_farm_cloudy.png';
    return 'background_farm_sunny.png';
  }
}
