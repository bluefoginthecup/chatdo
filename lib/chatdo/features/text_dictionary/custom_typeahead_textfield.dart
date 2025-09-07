// lib/features/text_dictionary/custom_typeahead_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'text_dictionary_utils.dart'; // 여기만 import
import 'dict_search_index.dart';
import 'text_dictionary_provider.dart'; // 경로 맞춰
import 'package:provider/provider.dart';



class CustomTypeAheadTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onSubmitted;
  final DictSearchIndex index;

  const CustomTypeAheadTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.index,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      direction: AxisDirection.up,
      suggestionsCallback: (pattern) {
        final seg = lastSegment(pattern).trim(); // <- pattern 쓰는 게 안전
        final prov = context.read<TextDictionaryProvider>();
        final index = prov.index;

        if (index == null || seg.isEmpty) return const <String>[];

        final hits = index.search(seg, limit: 8);

        assert(() {
          print('[TypeAhead] seg="$seg" -> hits=${hits.length} ${hits.take(5).toList()}');
          return true;
        }());

        return hits; // Iterable<String>
      },
      itemBuilder: (_, item) => ListTile(title: Text(item)),
      onSuggestionSelected: (item) async {
        // 최근사용 가중치 반영 + 저장
        final prov = context.read<TextDictionaryProvider>();
        prov.index?.bumpUsage(item);
        await prov.persistUsage();

        // 마지막 세그먼트 치환
        final next = replaceLastSegment(controller.text, item);
        controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '내용 입력',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (text) {
          context.read<TextDictionaryProvider>().add(text);
        },
      ),
    );
  }
}

