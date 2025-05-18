import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'package:chatdo/chatdo/services/weather_dialogue_evaluator.dart';

class WeatherService {
  final String _apiKey = 'a8f145a55231456c864db884f3ae3b5a';

  Future<Map<String, dynamic>> fetchWeatherFromCurrentLocation() async {
    print('[Weather] 사용하는 API 키: $_apiKey');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    final lat = position.latitude;
    final lon = position.longitude;

    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall'
          '?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&exclude=minutely,hourly,alerts',
    );

    final response = await http.get(url);
    print('[Weather] 호출 URL: $url');
    print('[Weather] 응답 상태: ${response.statusCode}');
    print('[Weather] 응답 내용: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('날씨 API 호출 실패: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    final currentTemp = data['current']['temp'];
    final currentDesc = data['current']['weather'][0]['description'];
    final today = data['daily'][0];
    final minTemp = today['temp']['min'];
    final maxTemp = today['temp']['max'];
    final todayDesc = today['weather'][0]['description'];
    final pop = today['pop'] ?? 0.0;
    final rainAmount = today['rain'] ?? 0.0;
    final uvi = data['current']['uvi'] ?? 0.0;

    return {
      'currentTemp': currentTemp,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'pop': pop,
      'rainAmount': rainAmount,
      'uvi': uvi,
      'description': currentDesc,
    };
  }

  Future<List<String>> getDialoguesFromJson() async {
    final rawData = await fetchWeatherFromCurrentLocation();

    final weather = WeatherData(
      temp: (rawData['currentTemp'] as num).toDouble(),
      minTemp: (rawData['minTemp'] as num).toDouble(),
      maxTemp: (rawData['maxTemp'] as num).toDouble(),
      pop: (rawData['pop'] as num?)?.toDouble() ?? 0.0,
      rainAmount: (rawData['rainAmount'] as num?)?.toDouble() ?? 0.0,
      uvi: (rawData['uvi'] as num?)?.toDouble() ?? 0.0,
      description: rawData['description'] ?? '',
    );


    final jsonStr = await rootBundle.loadString('assets/data/weather_dialogues.json');
    final List<dynamic> json = jsonDecode(jsonStr);

    final evaluator = WeatherDialogueEvaluator(weather);
    final matched = json.where((rule) => evaluator.evaluate(rule)).toList();
    matched.sort((a, b) => (a['priority'] ?? 999).compareTo(b['priority'] ?? 999));

    return matched.map((rule) {
      var text = rule['dialogue'].toString();;
      return text
          .replaceAll('{temp}', weather.temp.toStringAsFixed(1))
          .replaceAll('{pop}', (weather.pop * 100).round().toString())
          .replaceAll('{rain}', weather.rainAmount.toStringAsFixed(1))
          .replaceAll('{uvi}', weather.uvi.toStringAsFixed(1))
          .replaceAll('{minTemp}', weather.minTemp.toStringAsFixed(1))
          .replaceAll('{maxTemp}', weather.maxTemp.toStringAsFixed(1));
    }).toList();
  }
}
