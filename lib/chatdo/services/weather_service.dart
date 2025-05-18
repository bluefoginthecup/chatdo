import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

    return {
      'currentTemp': currentTemp,
      'currentDescription': currentDesc,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'description': todayDesc,
    };
  }
}
