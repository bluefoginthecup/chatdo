import 'package:flutter/material.dart';
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
  late List<ContentBlock> _blocks;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _blocks = List.from(widget.blocks);
    for (var i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type == 'text') {
        _controllers[i] = TextEditingController(text: _blocks[i].data);
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
      final newIndex = _blocks.length;
      _blocks.add(ContentBlock(type: 'text', data: ''));
      _controllers[newIndex] = TextEditingController();
      widget.onChanged(_blocks);
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      _controllers.remove(index);
      widget.onChanged(_blocks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._blocks.asMap().entries.map((entry) {
          final i = entry.key;
          final block = entry.value;

          if (block.type == 'text') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: widget.isEditing
                  ? GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _controllers[i],
                    maxLines: null,
                    decoration: const InputDecoration.collapsed(
                      hintText: '내용을 입력하세요',
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      _blocks[i] = ContentBlock(type: 'text', data: value);
                      widget.onChanged(_blocks);
                    },
                  ),
                ),
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Stack(
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
        }).toList(),

        if (widget.isEditing)
          Row(
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
          )
      ],
    );
  }
}
