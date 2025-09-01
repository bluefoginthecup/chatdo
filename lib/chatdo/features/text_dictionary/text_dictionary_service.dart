// lib/features/text_dictionary/text_dictionary_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firestore/repos/text_dictionary_repo.dart';

class TextDictionaryService {
  static const _key = 'text_dictionary_entries';

  Future<List<String>> getSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addSuggestion(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    if (!current.contains(text)) {
      current.insert(0, text);
      if (current.length > 30) {
        current.removeLast();
      }
      await prefs.setStringList(_key, current);
      await TextDictionaryRepo.save(current); // ✅ Firebase 저장
    }
  }

  Future<void> removeSuggestion(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(text);
    await prefs.setStringList(_key, current);
    await TextDictionaryRepo.save(current); // ✅ Firebase 저장
  }

  Future<void> loadFromFirebase() async {
    final entries = await TextDictionaryRepo.load(); // ✅ Firebase 불러오기
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, entries);
  }
}
