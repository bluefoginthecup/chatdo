// lib/utils/text_dictionary_utils.dart

// 레벤슈타인 거리
int levenshtein(String s, String t) {
  if (identical(s, t)) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  final m = s.length, n = t.length;
  final matrix = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) matrix[i][0] = i;
  for (var j = 0; j <= n; j++) matrix[0][j] = j;

  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = (s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1)) ? 0 : 1;
      final del = matrix[i - 1][j] + 1;
      final ins = matrix[i][j - 1] + 1;
      final sub = matrix[i - 1][j - 1] + cost;
      matrix[i][j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
  }
  return matrix[m][n];
}

// 마지막 토큰 추출 (기본: 콤마 기준, 끝의 공백 제거)
String lastSegment(String text) {
  final m = RegExp(r'([^,]+)$').firstMatch(text);
  return (m?.group(1) ?? '').trim();
}

// 마지막 토큰 치환 (뒤에 ", " 자동 추가)
String replaceLastSegment(String text, String replacement) {
  final before = text.replaceFirst(RegExp(r'([^,]+)$'), '').trimRight();
  return (before.isEmpty) ? '$replacement, ' : '$before$replacement, ';
}

// 텍스트 정규화: 공백/특수문자 제거, 소문자화
String normalize(String s) {
  var t = s.trim();
  t = t.replaceAll(RegExp(r'\s+'), '');
  t = t.replaceAll(RegExp(r'[^\uAC00-\uD7A3a-zA-Z0-9]'), '');
  return t.toLowerCase();
}

// 매칭: 부분일치 우선, 아니면 레벤슈타인 거리(길이>=3에서 거리<=2)
bool matches(String query, String candidate) {
  final q = normalize(query);
  if (q.isEmpty) return false;

  final c = normalize(candidate);
  if (c.isEmpty) return false;

  if (c.contains(q)) return true; // 빠른 길

  if (q.length >= 3) {
    final d = levenshtein(q, c);
    return d <= 2;
  }
  return false;
}
