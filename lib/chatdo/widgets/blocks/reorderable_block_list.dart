// reorderable_block_list.dart
import 'package:flutter/material.dart';
import '../../models/content_block.dart';

class ReorderableBlockList extends StatelessWidget {
  final List<MapEntry<String, ContentBlock>> entries;
  final bool isEditing;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(int index, MapEntry<String, ContentBlock> entry) itemBuilder;

  const ReorderableBlockList({
    super.key,
    required this.entries,
    required this.isEditing,
    required this.onReorder,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: onReorder,
      buildDefaultDragHandles: false,
      children: [
        for (int i = 0; i < entries.length; i++)
          itemBuilder(i, entries[i]),
      ],
    );
  }
}
