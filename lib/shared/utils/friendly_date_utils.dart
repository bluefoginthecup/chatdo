// lib/utils/date_utils.dart

import 'package:intl/intl.dart';

String getFriendlyDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  final weekday = DateFormat('EEEE', 'ko_KR').format(date); // 예: 일요일
  final formattedDate = DateFormat('yyyy년 M월 d일').format(date);

  switch (diff) {
    case -2:
      return '그저께 ($formattedDate $weekday)';
    case -1:
      return '어제 ($formattedDate $weekday)';
    case 0:
      return '오늘 ($formattedDate $weekday)';
    case 1:
      return '내일 ($formattedDate $weekday)';
    case 2:
      return '모레 ($formattedDate $weekday)';
    default:
      return '$formattedDate $weekday';
  }
}
