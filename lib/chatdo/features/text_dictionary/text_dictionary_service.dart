// lib/features/text_dictionary/text_dictionary_service.dart
import 'package:shared_preferences/shared_preferences.dart';

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
      current.insert(0, text); // 가장 최근 항목이 앞으로
      if (current.length > 30) {
        current.removeLast();
      }
      await prefs.setStringList(_key, current);
    }
  }

  Future<void> removeSuggestion(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(text);
    await prefs.setStringList(_key, current);
  }
}

