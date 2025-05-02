import 'package:flutter/material.dart';
import '/chatdo/constants/tag_list.dart';

class TagFilterBar extends StatelessWidget {
  final String? selectedTag;
  final void Function(String?) onTagSelected;

  const TagFilterBar({
    super.key,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: allTags.map((tag) {
          final isSelected = selectedTag == tag;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) {
                onTagSelected(isSelected ? null : tag);
              },
              selectedColor: Colors.orangeAccent,
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
