import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/content_block.dart';


class BlockEditor extends StatefulWidget {
  final List<ContentBlock> blocks;
  final bool isEditing;
  final void Function(List<ContentBlock>) onChanged;
  final VoidCallback onImageAdd;

  const BlockEditor({
    super.key,
    required this.blocks,
    required this.isEditing,
    required this.onChanged,
    required this.onImageAdd,
  });

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  late List<MapEntry<String, ContentBlock>> _blockEntries;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final uuid = const Uuid();
    _blockEntries = widget.blocks.map((b) => MapEntry(uuid.v4(), b)).toList();
    for (final entry in _blockEntries) {
      if (entry.value.type == 'text') {
        _controllers[entry.key] = TextEditingController(text: entry.value.data);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTextBlock() {
    setState(() {
      final uuid = const Uuid().v4();
      _blockEntries.add(MapEntry(uuid, ContentBlock(type: 'text', data: '')));
      _controllers[uuid] = TextEditingController();
      widget.onChanged(_blockEntries.map((e) => e.value).toList());
    });
  }

  void _removeBlock(int index) {
    setState(() {
      final key = _blockEntries[index].key;
      _blockEntries.removeAt(index);
      _controllers.remove(key);
      widget.onChanged(_blockEntries.map((e) => e.value).toList());
    });
  }

  void _reorderBlock(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _blockEntries.removeAt(oldIndex);
      _blockEntries.insert(newIndex, item);
      widget.onChanged(_blockEntries.map((e) => e.value).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderBlock,
      buildDefaultDragHandles: false,
      children: [
        ..._blockEntries.asMap().entries.map((entry) {
          final i = entry.key;
          final blockEntry = entry.value;
          final key = blockEntry.key;
          final block = blockEntry.value;

          if (block.type == 'text') {
            return ListTile(
              key: ValueKey(key),
              title: widget.isEditing
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0, top: 12),
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _controllers[key],
                        maxLines: null,
                        decoration: const InputDecoration.collapsed(
                          hintText: '내용을 입력하세요',
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (value) {
                          _blockEntries[i] = MapEntry(
                            key,
                            ContentBlock(type: 'text', data: value),
                          );
                          widget.onChanged(_blockEntries.map((e) => e.value).toList());
                        },
                      ),
                    ),
                  ),
                ],
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  block.data,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          } else if (block.type == 'image') {
            return ListTile(
              key: ValueKey(key),
              title: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.network(block.data),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeBlock(i),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        if (widget.isEditing)
          ListTile(
            key: const ValueKey("block-add-buttons"),
            title: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addTextBlock,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('텍스트 추가'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onImageAdd,
                  icon: const Icon(Icons.image),
                  label: const Text('이미지 추가'),
                ),
              ],
            ),
          )
      ],
    );
  }
}
