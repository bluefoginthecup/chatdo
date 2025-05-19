import 'package:chatdo/chatdo/data/weather_repository.dart';
import 'package:chatdo/game/components/speech_bubble_component.dart';
import 'package:flame/components.dart';
import 'package:chatdo/game/room/jordy_sprite.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:chatdo/chatdo/services/weather_service.dart';
import 'package:chatdo/chatdo/models/weather_data.dart';
import 'package:chatdo/chatdo/services/weather_dialogue_evaluator.dart';
import 'package:chatdo/chatdo/data/weather_repository.dart';

class WeatherSceneController {
  final WeatherRepository _repository = WeatherRepository();

  // ✅ 여기 추가
  String _getBackgroundPath(String description) {
    if (description.contains('rain')) return 'background_farm_rainy.png';
    if (description.contains('snow')) return 'background_farm_snowy.png';
    if (description.contains('cloud')) return 'background_farm_cloudy.png';
    return 'background_farm_sunny.png';
  }

  /// ✅ 1. 아침용 텍스트 + 텃밭 배경 리턴
  Future<(String, String)> getWeatherDialogueAndBg(String description) async {
    try {
      final bgImage = _getBackgroundPath(description);
      final text = '오늘 날씨는 $description입니다.';
      return (text, bgImage);
    }catch (e) {
      print('[Weather] ❌ ERROR in getWeatherDialogueAndBg: $e');
      return ('날씨 정보를 불러오지 못했어요.', 'background_garden.png');
    }
  }

  /// ✅ 2. 9시 이후용 창문 날씨 배경(추후 구현)
  Future<String> getIndoorBackground(String description) async {
    if (description.contains('rain')) {
      return 'room_bg_thunderbolt.png';
    } else if (description.contains('snow')) {
      return 'room_bg_snowy.png';
    } else if (description.contains('cloud')) {
      return 'room_bg_cloudy.png';
    } else {
      return 'room_bg_sunny.png';
    }
  }


  /// ✅ 3. 날씨 JSON 대사 리스트 반환

    Future<List<String>> getWeatherDialogues() async {
      final rawData = await _repository.getCachedOrFetchWeather(); // ✅ 캐시된 데이터 재활용


    final weather = WeatherData(
      temp: (rawData['currentTemp'] as num).toDouble(),
      feelsLike: (rawData['feels_like'] as num?)?.toDouble() ?? 0.0,
      minTemp: (rawData['minTemp'] as num).toDouble(),
      maxTemp: (rawData['maxTemp'] as num).toDouble(),
      pop: (rawData['pop'] as num?)?.toDouble() ?? 0.0,
      rainAmount: (rawData['rainAmount'] as num?)?.toDouble() ?? 0.0,
      uvi: (rawData['uvi'] as num?)?.toDouble() ?? 0.0,
      humidity: (rawData['humidity'] as num?)?.toDouble() ?? 0.0,
      wind: (rawData['wind'] as num?)?.toDouble() ?? 0.0,
      description: rawData['description'] ?? '',
    );

    final jsonStr = await rootBundle.loadString('assets/data/weather_dialogues.json');
    final List<dynamic> json = jsonDecode(jsonStr);

    final evaluator = WeatherDialogueEvaluator(weather);
    final matched = json.where((rule) => evaluator.evaluate(rule)).toList();
    matched.sort((a, b) => (a['priority'] ?? 999).compareTo(b['priority'] ?? 999));

    return matched.map((rule) {
      var text = rule['dialogue'].toString();
      return text
          .replaceAll('{temp}', weather.temp.toStringAsFixed(1))
          .replaceAll('{feels_like}', weather.feelsLike.toStringAsFixed(1))
          .replaceAll('{pop}', (weather.pop * 100).round().toString())
          .replaceAll('{rain}', weather.rainAmount.toStringAsFixed(1))
          .replaceAll('{uvi}', weather.uvi.toStringAsFixed(1))
          .replaceAll('{humidity}', weather.humidity.toStringAsFixed(1))
          .replaceAll('{wind}', weather.wind.toStringAsFixed(1))
          .replaceAll('{minTemp}', weather.minTemp.toStringAsFixed(1))
          .replaceAll('{maxTemp}', weather.maxTemp.toStringAsFixed(1));
    }).toList();
  }
}
