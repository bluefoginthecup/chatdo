import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/weather_data.dart';

// 2. 조건 평가기
class WeatherDialogueEvaluator {
  final WeatherData data;

  WeatherDialogueEvaluator(this.data);

  bool evaluate(Map<String, dynamic> rule) {
    final target = rule['target'];
    final operator = rule['operator'];
    final value = rule['value'];
    final min = rule['min'];
    final max = rule['max'];

    dynamic actual = _getFieldValue(target);

    switch (operator) {
      case 'contains':
        return actual.toString().contains(value);
      case 'equals':
        return actual == value;
      case 'gte':
        return actual >= value;
      case 'gt':
        return actual > value;
      case 'lte':
        return actual <= value;
      case 'lt':
        return actual < value;
      case 'between':
        return actual >= min && actual <= max;
      default:
        return false;
    }
  }

  dynamic _getFieldValue(String target) {
    switch (target) {
      case 'temp': return data.temp;
      case 'minTemp': return data.minTemp;
      case 'maxTemp': return data.maxTemp;
      case 'pop': return data.pop;
      case 'rainAmount': return data.rainAmount;
      case 'uvi': return data.uvi;
      case 'description': return data.description;
      default: return null;
    }
  }
}

// 3. JSON 파싱 및 대사 리스트 생성
Future<List<String>> getDialoguesFromJson(WeatherData data, String jsonStr) async {
  final List<dynamic> rules = jsonDecode(jsonStr);
  final evaluator = WeatherDialogueEvaluator(data);
  final List<Map<String, dynamic>> matchedRules = [];

  for (final rule in rules) {
    if (evaluator.evaluate(rule)) {
      matchedRules.add(rule);
    }
  }

  matchedRules.sort((a, b) => (a['priority'] ?? 999).compareTo(b['priority'] ?? 999));

  return matchedRules.map((rule) {
    var text = rule['dialogue'];
    return text
        .replaceAll('{temp}', data.temp.toStringAsFixed(1))
        .replaceAll('{pop}', (data.pop * 100).round().toString())
        .replaceAll('{rain}', data.rainAmount.toStringAsFixed(1))
        .replaceAll('{uvi}', data.uvi.toStringAsFixed(1));
  }).toList();
}

// 4. 말풍선 출력 순차 처리
void showDialoguesSequentially(List<String> dialogues, void Function(String) showBubble) async {
  for (final text in dialogues) {
    showBubble(text);
    await Future.delayed(Duration(seconds: 1));
  }
}
