// lib/features/text_dictionary/text_dictionary_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../data/firestore/repos/text_dictionary_repo.dart';
import 'package:hive/hive.dart';
import 'dart:convert';


class TextDictionaryService {
  static const _key = 'text_dictionary_entries';
  static const _usageBox = 'textDictUsage';
  static const _usageKey = 'usage';


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

  /// 최근 사용 가중치 로드
  static Future<Map<String, dynamic>?> loadUsage() async {
    final box = await Hive.openBox<String>(_usageBox);
    final raw = box.get(_usageKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// 최근 사용 가중치 저장
  static Future<void> saveUsage(Map<String, dynamic> json) async {
    final box = await Hive.openBox<String>(_usageBox);
    await box.put(_usageKey, jsonEncode(json));
  }
}
