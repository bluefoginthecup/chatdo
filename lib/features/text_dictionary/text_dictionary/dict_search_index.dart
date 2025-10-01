// lib/chatdo/dict/dict_search_index.dart
import 'dart:math' as math;

const List<String> _CHO = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ'
];

bool _isHangulSyllable(int code) => code >= 0xAC00 && code <= 0xD7A3;
bool _isChoseongOnly(String s) {
  if (s.isEmpty) return false;
  for (final r in s.runes) {
    if (!(r >= 0x3131 && r <= 0x314E)) return false; // ㄱ~ㅎ
  }
  return true;
}

String extractChosung(String input) {
  final sb = StringBuffer();
  for (final r in input.runes) {
    if (_isHangulSyllable(r)) {
      final idx = r - 0xAC00;
      final choIndex = idx ~/ (21 * 28);
      sb.write(_CHO[choIndex]);
    } else if (r == 0x20) {
      // 공백은 패스 (토큰 초성은 별도)
      continue;
    }
  }
  return sb.toString();
}

String normalizeForMatch(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');
}

class _Usage {
  int count;
  int lastMs;
  _Usage({this.count = 0, this.lastMs = 0});
  Map<String, dynamic> toJson() => {'c': count, 't': lastMs};
  static _Usage fromJson(Map<String, dynamic> j) =>
      _Usage(count: (j['c'] ?? 0) as int, lastMs: (j['t'] ?? 0) as int);
  void bump() {
    count += 1;
    lastMs = DateTime.now().millisecondsSinceEpoch;
  }
}

class _Entry {
  final String original;
  final String normalized;
  final String chosung;
  final List<String> tokenChosungs; // "서울대 병원" -> ["ㅅㅇㄷ","ㅂㅇ"]
  _Entry._(this.original, this.normalized, this.chosung, this.tokenChosungs);
  factory _Entry.fromWord(String w) {
    final norm = normalizeForMatch(w);
    final cho = extractChosung(w);
    final tokens = w
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(extractChosung)
        .where((t) => t.isNotEmpty)
        .toList();
    return _Entry._(w, norm, cho, tokens);
  }
}

class DictSearchIndex {
  final List<_Entry> _entries = [];
  final Map<String, Set<int>> _choPrefix = {};
  final Map<String, Set<int>> _tokenChoPrefix = {};
  final Map<String, _Usage> _usage = {}; // key = original

  DictSearchIndex.fromWords(List<String> words) {
    for (final w in words) {
      _addWord(w);
    }
  }

  // ---- public API ----
  List<String> search(String input, {int limit = 20}) {
    final q = input.trim();
    if (q.isEmpty) return const [];
    if (_isChoseongOnly(q)) {
      return _searchChosung(q, limit: limit).map((e) => e.original).toList();
    } else {
      return _searchNormal(q, limit: limit).map((e) => e.original).toList();
    }
  }

  void bumpUsage(String word) {
    (_usage[word] ??= _Usage()).bump();
  }

  Map<String, dynamic> exportUsage() {
    final m = <String, dynamic>{};
    _usage.forEach((k, v) => m[k] = v.toJson());
    return m;
  }

  void importUsage(Map<String, dynamic> json) {
    _usage.clear();
    json.forEach((k, v) {
      if (v is Map<String, dynamic>) _usage[k] = _Usage.fromJson(v);
    });
  }

  // ---- helpers ----
  void _addWord(String word) {
    final e = _Entry.fromWord(word);
    final idx = _entries.length;
    _entries.add(e);
    _usage.putIfAbsent(e.original, () => _Usage());
    _addAllPrefixes(_choPrefix, e.chosung, idx);
    for (final t in e.tokenChosungs) {
      _addAllPrefixes(_tokenChoPrefix, t, idx);
    }
  }

  void _addAllPrefixes(Map<String, Set<int>> map, String s, int idx) {
    for (int i = 1; i <= s.length; i++) {
      final p = s.substring(0, i);
      (map[p] ??= <int>{}).add(idx);
    }
  }

  List<_Entry> _searchChosung(String q, {int limit = 20}) {
    final a = _choPrefix[q] ?? const <int>{};
    final b = _tokenChoPrefix[q] ?? const <int>{};
    final ids = <int>{...a, ...b}.toList();

    ids.sort((i1, i2) {
      final e1 = _entries[i1], e2 = _entries[i2];

      // 1) 전체초성 startsWith 우선
      int w1 = (e1.chosung.startsWith(q) ? 2 : 0) +
          (e1.tokenChosungs.any((t) => t.startsWith(q)) ? 1 : 0);
      int w2 = (e2.chosung.startsWith(q) ? 2 : 0) +
          (e2.tokenChosungs.any((t) => t.startsWith(q)) ? 1 : 0);
      if (w1 != w2) return w2 - w1;

      // 2) 사용 가중치
      final u1 = _scoreUsage(e1.original);
      final u2 = _scoreUsage(e2.original);
      if (u1 != u2) return u2.compareTo(u1);

      // 3) 가나다 안정 정렬
      return e1.original.compareTo(e2.original);
    });

    return ids.take(limit).map((i) => _entries[i]).toList();
  }

  List<_Entry> _searchNormal(String input, {int limit = 20}) {
    final q = normalizeForMatch(input);
    final hits = _entries.where((e) => e.normalized.contains(q)).toList();

    hits.sort((a, b) {
      // 1) 시작일치 우선
      final aStart = a.normalized.startsWith(q) ? 1 : 0;
      final bStart = b.normalized.startsWith(q) ? 1 : 0;
      if (aStart != bStart) return bStart - aStart;

      // 2) 사용 가중치
      final u1 = _scoreUsage(a.original);
      final u2 = _scoreUsage(b.original);
      if (u1 != u2) return u2.compareTo(u1);

      // 3) 가나다
      return a.original.compareTo(b.original);
    });

    return hits.take(limit).toList();
  }

  double _scoreUsage(String word) {
    final u = _usage[word];
    if (u == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final days = (now - u.lastMs) / (1000 * 60 * 60 * 24);
    final recentBonus = (u.lastMs == 0)
        ? 0.0
        : (days > 7 ? 0.0 : (7 - days)); // 최근 7일 내 선택 보너스(0~7)
    final freq = math.log(u.count + 1) / math.log(2); // 선택수 로그 스케일
    return freq * 4 + recentBonus; // 가중치 튜닝 포인트
  }
}
