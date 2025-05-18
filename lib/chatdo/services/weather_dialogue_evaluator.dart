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

    if (actual == null) return false; // 🛡 null이면 무시

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
      case 'temp':
        return data.temp;
      case 'feelsLike':
        return data.feelsLike;
      case 'minTemp':
        return data.minTemp;
      case 'maxTemp':
        return data.maxTemp;
      case 'tempGap':
        return data.tempGap;
      case 'pop':
        return data.pop;
      case 'rainAmount':
        return data.rainAmount;
      case 'uvi':
        return data.uvi;
      case 'humidity':
        return data.humidity;
      case 'wind':
        return data.wind;
      case 'description':
        return data.description;
    // 👇 계산된 조건 필드들
      case 'isBigTempGap':
        return data.isBigTempGap;
      case 'isHotDay':
        return data.isHotDay;
      case 'isFreezing':
        return data.isFreezing;
      case 'isRainyAndCold':
        return data.isRainyAndCold;
      case 'feelsLikeDiff':
        return data.feelsLikeDiff;
      case 'isFeelsDifferent':
        return data.isFeelsDifferent;
      case 'isDryAndWindy':
        return data.isDryAndWindy;
      default:
        return null;
    }
  }


}
