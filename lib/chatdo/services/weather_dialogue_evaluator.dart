import '../models/weather_data.dart';

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
