// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';
//
// class WeatherService {
//   final String _apiKey = '7340e5c10e98d532bd2c205f745dd365'; // TODO: 여기에 OpenWeatherMap API 키 입력
//
//   Future<Map<String, dynamic>> fetchWeatherFromCurrentLocation() async {
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.low,
//     );
//
//     final lat = position.latitude;
//     final lon = position.longitude;
//
//     final url = Uri.parse(
//       'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=kr',
//     );
//
//     final response = await http.get(url);
//
//     if (response.statusCode != 200) {
//       throw Exception('날씨 정보를 불러오는 데 실패했습니다.');
//     }
//
//     return jsonDecode(response.body);
//   }
// }
