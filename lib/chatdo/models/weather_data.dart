class WeatherData {
  final double temp;         // 현재 기온
  final double feelsLike;    // 체감온도
  final double minTemp;      // 오늘 최저기온
  final double maxTemp;      // 오늘 최고기온
  final double pop;          // 강수확률 (0.0 ~ 1.0)
  final double rainAmount;   // 강수량 (mm)
  final double uvi;          // 자외선 지수
  final double humidity;     // 습도 (%)
  final double wind;         // 풍속 (m/s)
  final String description;  // 날씨 설명

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.minTemp,
    required this.maxTemp,
    required this.pop,
    required this.rainAmount,
    required this.uvi,
    required this.humidity,
    required this.wind,
    required this.description,
  });

  // ✅ 파생 필드
  double get tempGap => (maxTemp - minTemp).abs();

  bool get isBigTempGap => tempGap >= 10;

  bool get isHotDay => maxTemp >= 30;

  bool get isFreezing => minTemp < 0;

  bool get isRainyAndCold => rainAmount > 0 && temp < 10;

  double get feelsLikeDiff => (temp - feelsLike).abs();

  bool get isFeelsDifferent => feelsLikeDiff >= 3;

  bool get isDryAndWindy => humidity <= 40 && wind >= 5;
}
