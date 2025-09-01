
// lib/features/text_dictionary/custom_typeahead_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'text_dictionary_service.dart';

class CustomTypeAheadTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onSubmitted;

  const CustomTypeAheadTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: InputDecoration(
          labelText: hintText,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted,
      ),
      suggestionsCallback: (pattern) async {
        final service = TextDictionaryService();
        final all = await service.getSuggestions();
        return all.where(
              (s) => s.toLowerCase().contains(pattern.toLowerCase()),
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion));
      },
      onSuggestionSelected: (suggestion) {
        controller.text = suggestion;
      },
    );
  }
}

