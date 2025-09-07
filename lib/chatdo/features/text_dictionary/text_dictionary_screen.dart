
// lib/features/text_dictionary/text_dictionary_screen.dart
import 'package:flutter/material.dart';
import 'text_dictionary_service.dart';

class TextDictionaryScreen extends StatefulWidget {
  const TextDictionaryScreen({super.key});

  @override
  State<TextDictionaryScreen> createState() => _TextDictionaryScreenState();
}

class _TextDictionaryScreenState extends State<TextDictionaryScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = TextDictionaryService();
    final items = await service.getSuggestions();
    setState(() {
      _entries = items;
    });
  }

  Future<void> _addEntry(String text) async {
    final service = TextDictionaryService();
    await service.addSuggestion(text);
    _controller.clear();
    await _load();
  }

  Future<void> _removeEntry(String text) async {
    final service = TextDictionaryService();
    await service.removeSuggestion(text);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('텍스트 사전 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '새 문장 추가',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addEntry,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final text = _entries[index];
                  return ListTile(
                    title: Text(text),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeEntry(text),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
