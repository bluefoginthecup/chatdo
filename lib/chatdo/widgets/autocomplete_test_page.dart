import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutocompleteTestPage extends StatefulWidget {
  const AutocompleteTestPage({super.key});

  @override
  State<AutocompleteTestPage> createState() => _AutocompleteTestPageState();
}

class _AutocompleteTestPageState extends State<AutocompleteTestPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _suggestions = prefs.getStringList('custom_suggestions') ?? [];
    });
  }

  Future<void> _saveSuggestion(String input) async {
    final prefs = await SharedPreferences.getInstance();
    if (input.trim().isEmpty) return;

    if (!_suggestions.contains(input)) {
      _suggestions.insert(0, input);
      if (_suggestions.length > 20) {
        _suggestions = _suggestions.sublist(0, 20); // 최대 20개까지만 저장
      }
      await prefs.setStringList('custom_suggestions', _suggestions);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자동완성 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '입력해보세요',
                  border: OutlineInputBorder(),
                ),
              ),
              suggestionsCallback: (pattern) {
                return _suggestions.where(
                        (s) => s.toLowerCase().contains(pattern.toLowerCase()));
              },
              itemBuilder: (context, suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSuggestionSelected: (suggestion) {
                _controller.text = suggestion;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final input = _controller.text.trim();
                if (input.isNotEmpty) {
                  await _saveSuggestion(input);
                  _controller.clear();
                }
              },
              child: const Text('입력 저장'),
            ),
          ],
        ),
      ),
    );
  }
}
