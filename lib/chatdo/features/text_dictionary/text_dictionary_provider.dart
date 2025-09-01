// lib/features/text_dictionary/text_dictionary_provider.dart
import 'package:flutter/material.dart';
import 'text_dictionary_repo.dart';

class TextDictionaryProvider extends ChangeNotifier {
  List<String> _entries = [];

  List<String> get entries => _entries;

  Future<void> load() async {
    _entries = await TextDictionaryRepo.load();
    notifyListeners();
  }

  Future<void> update(List<String> newEntries) async {
    _entries = newEntries;
    await TextDictionaryRepo.save(newEntries);
    notifyListeners();
  }

  void add(String word) {
    if (!_entries.contains(word)) {
      _entries.add(word);
      notifyListeners();
      TextDictionaryRepo.save(_entries); // 저장도 바로 해줌
    }
  }

  void remove(String word) {
    _entries.remove(word);
    notifyListeners();
    TextDictionaryRepo.save(_entries);
  }
}
