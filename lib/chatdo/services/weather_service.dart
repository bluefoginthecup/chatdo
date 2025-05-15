import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String _apiKey = '7340e5c10e98d532bd2c205f745dd365'; // TODO: 여기에 OpenWeatherMap API 키 입력

  Future<Map<String, dynamic>> fetchWeatherFromCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    print('[Weather] 위치 권한 상태: $permission');

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final request = await Geolocator.requestPermission();
      print('[Weather] 위치 권한 요청 결과: $request');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    final lat = position.latitude;
    final lon = position.longitude;


    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=kr',
    );

    final response = await http.get(url);
    print('[Weather] API 응답: ${response.body}');

    return jsonDecode(response.body);
  }


}
