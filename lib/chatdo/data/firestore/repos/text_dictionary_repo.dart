// lib/data/firestore/repos/text_dictionary_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../paths.dart';

class TextDictionaryRepo {
  static Future<DocumentReference<Map<String, dynamic>>?> _getRef() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final db = FirebaseFirestore.instance;
    return currentPaths(db).textDictionary(uid);
  }

  static Future<void> save(List<String> entries) async {
    final ref = await _getRef();
    if (ref == null) return;
    await ref.set({ 'entries': entries });
  }

  static Future<List<String>> load() async {
    final ref = await _getRef();
    if (ref == null) return [];
    final doc = await ref.get();
    if (doc.exists && doc.data()?['entries'] is List) {
      return List<String>.from(doc.data()!['entries']);
    }
    return [];
  }
}