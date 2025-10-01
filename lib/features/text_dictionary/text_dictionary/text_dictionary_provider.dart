// lib/features/text_dictionary/text_dictionary_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/firestore/repos/text_dictionary_repo.dart';
import 'dict_search_index.dart'; // ← 경로 니 프로젝트에 맞춰

import 'text_dictionary_service.dart'; // ← 사용기록 저장/로드 (니가 쓰던 곳)

class TextDictionaryProvider with ChangeNotifier {
  // --- 사전 단어 ---
  List<String> _words = [];
  List<String> get words => List.unmodifiable(_words);

  // --- 검색 인덱스(초성 + 최근사용 가중치) ---
  DictSearchIndex? _index;
  DictSearchIndex? get index => _index;

  bool get isReady => _index != null;

  // =============== 초기 로드 ===============
  Future<void> load() async {
    // 1) 단어 로드 (Repo로 통일)
    _words = await TextDictionaryRepo.load(); // 없으면 [] 반환하도록 구현

    // ✅ 간단 테스트: Firestore에서 뭐가 왔는지 확인
    print(
        '[DICT] from Firestore: ${_words.length} entries, sample=${_words.take(5).toList()}');

    // 2) 인덱스 구성
    _rebuildIndex();

    // ✅ 인덱스 테스트: "ㅇ" 검색해보기
    if (_index != null) {
      final testHits = _index!.search('ㅇ', limit: 5);
      print('[DICT] search "ㅇ" => $testHits');
    }
    // 3) 사용기록 복원 (있으면)
    final usage =
        await TextDictionaryService.loadUsage(); // Map<String,dynamic>? 예상
    if (usage != null && _index != null) {
      _index!.importUsage(usage);
    }

    notifyListeners();
  }

  // 인덱스 재구성 (단어 변경 시 호출)
  void _rebuildIndex() {
    _index = DictSearchIndex.fromWords(_words);
  }

  // =============== 전체 교체/갱신 ===============
  Future<void> setWords(List<String> newWords) async {
    _words = List.from(newWords);
    _rebuildIndex();
    // 기존 사용기록 유지
    final usage = await TextDictionaryService.loadUsage();
    if (usage != null) _index!.importUsage(usage);

    await TextDictionaryRepo.save(_words);
    notifyListeners();
  }

  // =============== 단어 추가/삭제 ===============
  Future<void> add(String word) async {
    if (word.trim().isEmpty) return;
    if (_words.contains(word)) return;

    _words.add(word);
    _rebuildIndex();
    await TextDictionaryRepo.save(_words);
    notifyListeners();
  }

  Future<void> remove(String word) async {
    final removed = _words.remove(word);
    if (!removed) return;

    _rebuildIndex();
    await TextDictionaryRepo.save(_words);
    notifyListeners();
  }

  // 여러 개 한꺼번에 추가/삭제가 잦으면 배치 메서드도 있어도 좋다.
  Future<void> update(List<String> newEntries) async {
    await setWords(newEntries);
  }

  // =============== 사용기록 ===============
  Future<void> persistUsage() async {
    if (_index == null) return;
    await TextDictionaryService.saveUsage(_index!.exportUsage());
  }
}
