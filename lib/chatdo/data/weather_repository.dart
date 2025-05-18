import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '/chatdo/services/weather_service.dart';


class WeatherRepository {
  final WeatherService _service = WeatherService();

Future<(String text, String bgImagePath)> getTodayWeather() async {
    final weather = await _service.fetchWeatherFromCurrentLocation();
    final description = weather['description'] ?? 'clear';
    final bgImagePath = _getBackgroundPath(description);
    final text = '오늘 날씨는 ${description}입니다.';
    return (text, bgImagePath);
  }

  String _getBackgroundPath(String description) {
    if (description.contains('rain')) return 'background_farm_rainy.png';
    if (description.contains('snow')) return 'background_farm_snowy.png';
    if (description.contains('cloud')) return 'background_farm_cloudy.png';
    return 'background_farm_sunny.png';
  }

  /// ✅ 여기 추가
  Future<String> getTodayWeatherDescription() async {
    final weather = await _service.fetchWeatherFromCurrentLocation();
    return weather['description'] ?? 'clear';
  }
}
