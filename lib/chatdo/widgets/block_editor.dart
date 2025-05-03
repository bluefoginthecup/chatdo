import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/content_block.dart';

class BlockEditor extends StatefulWidget {
  final List<ContentBlock> blocks;
  final bool isEditing;
  final void Function(List<ContentBlock>) onChanged;

  const BlockEditor({
    super.key,
    required this.blocks,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  late List<ContentBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = List.from(widget.blocks);
  }

  void _addTextBlock() {
    setState(() {
      _blocks.add(ContentBlock(type: 'text', data: ''));
      widget.onChanged(_blocks);
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      widget.onChanged(_blocks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._blocks.asMap().entries.map((entry) {
          final i = entry.key;
          final block = entry.value;

          if (block.type == 'text') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: TextEditingController(text: block.data),
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '텍스트 블록',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _blocks[i] = ContentBlock(type: 'text', data: value);
                  widget.onChanged(_blocks);
                },
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
                onPressed: () {
                  // TODO: 이미지 업로드 처리
                },
                icon: const Icon(Icons.image),
                label: const Text('이미지 추가'),
              ),
            ],
          )
      ],
    );
  }
}
