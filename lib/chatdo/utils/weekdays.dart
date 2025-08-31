// 요일 상수/헬퍼 (KO 기준)
const List<String> kWeekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];
const Map<String, int> kWeekdayOrderKo = {
  '월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6, '일': 7,
};

/// 요일 키 리스트를 고정 순서로 정렬
List<String> sortWeekdayKeys(Iterable<String> days) {
  final list = days.map((e) => e.toString()).toList();
  list.sort((a, b) => (kWeekdayOrderKo[a] ?? 99).compareTo(kWeekdayOrderKo[b] ?? 99));
  return list;
}

/// 요일→시간 맵(Map<String,String>)을 고정 순서로 정렬한 엔트리 리스트 반환
List<MapEntry<String, String>> sortWeekdayMap(Map<String, String> m) {
  final entries = m.entries.toList();
  entries.sort((a, b) =>
      (kWeekdayOrderKo[a.key] ?? 99).compareTo(kWeekdayOrderKo[b.key] ?? 99));
  return entries;
}
