// lib/features/text_dictionary/custom_typeahead_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'text_dictionary_utils.dart'; // 여기만 import

class CustomTypeAheadTextField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> dictionary;
  final String hintText;
  final void Function(String)? onSubmitted;

  const CustomTypeAheadTextField({
    super.key,
    required this.controller,
    required this.dictionary,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      direction: AxisDirection.up,
      suggestionsCallback: (_) {
        final seg = lastSegment(controller.text);
        if (seg.isEmpty) return const Iterable<String>.empty();
        return dictionary.where((e) => matches(seg, e)).take(8);
      },
      itemBuilder: (_, item) => ListTile(title: Text(item)),
      onSuggestionSelected: (item) {
        final next = replaceLastSegment(controller.text, item);
        controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: InputDecoration(
          labelText: hintText,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

