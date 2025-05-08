// ✅ 드래그 핸들 왼쪽 분리 + 드롭 위치 강조 버전 BlockEditor

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/content_block.dart';
import '../../utils/image_uploader.dart';
import 'image_block_widget.dart';
import 'text_block_widget.dart';
import 'select_image_and_add.dart';

class BlockEditor extends StatefulWidget {
  final List<ContentBlock> blocks;
  final bool isEditing;
  final void Function(List<ContentBlock>) onChanged;
  final String logId;
  final void Function()? onRequestSave;

  const BlockEditor({
    super.key,
    required this.blocks,
    required this.isEditing,
    required this.onChanged,
    required this.logId,
    this.onRequestSave,
  });

  @override
  State<BlockEditor> createState() => BlockEditorState();
}

class BlockEditorState extends State<BlockEditor> {
  late List<MapEntry<String, ContentBlock>> _entries;
  final Map<String, TextEditingController> _controllers = {};

  List<ContentBlock> getCurrentBlocks() => _entries.map((e) => e.value).toList();

  @override
  void initState() {
    super.initState();
    final uuid = const Uuid();
    _entries = widget.blocks.map((b) => MapEntry(uuid.v4(), b)).toList();
    for (var entry in _entries) {
      if (entry.value.type == 'text') {
        _controllers[entry.key] = TextEditingController(text: entry.value.data);
      }
    }
  }

  @override
  void didUpdateWidget(covariant BlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blocks != oldWidget.blocks) {
      final uuid = const Uuid();
      final newEntries = <MapEntry<String, ContentBlock>>[];
      for (int i = 0; i < widget.blocks.length; i++) {
        final newBlock = widget.blocks[i];
        final oldBlock = i < _entries.length ? _entries[i] : null;
        final key = oldBlock?.key ?? uuid.v4();
        newEntries.add(MapEntry(key, newBlock));
        if (newBlock.type == 'text' && !_controllers.containsKey(key)) {
          _controllers[key] = TextEditingController(text: newBlock.data);
        }
      }
      setState(() => _entries = newEntries);
    }
  }

  void _reorder(int fromIndex, int toIndex) {
    setState(() {
      final moved = _entries.removeAt(fromIndex);
      _entries.insert(toIndex, moved);
      widget.onChanged(_entries.map((e) => e.value).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_entries.length, (index) {
          final entry = _entries[index];

          return DragTarget<int>(
            onWillAccept: (from) => from != index,
            onAccept: (from) => _reorder(from, index),
            builder: (context, candidate, rejected) {
              final isTargeted = candidate.isNotEmpty;
              return Container(
                decoration: isTargeted
                    ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isEditing)
                      LongPressDraggable<int>(
                        data: index,
                        feedback: Material(
                          child: Container(
                            width: MediaQuery.of(context).size.width - 32,
                            padding: const EdgeInsets.all(8),
                            color: Colors.amber.withOpacity(0.6),
                            child: _buildBlock(entry, index),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_handle, color: Colors.grey),
                        ),
                      ),
                    Expanded(child: _buildBlock(entry, index)),
                  ],
                ),
              );
            },
          );
        }),

        if (widget.isEditing)
          ListTile(
            title: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final id = const Uuid().v4();
                    setState(() {
                      _entries.add(MapEntry(id, ContentBlock(type: 'text', data: '')));
                      _controllers[id] = TextEditingController();
                      widget.onChanged(_entries.map((e) => e.value).toList());
                    });
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('텍스트 추가'),
                ),
                SelectImageAndAdd(
                  logId: widget.logId,
                  onImagesAdded: (newBlocks) {
                    setState(() {
                      for (final block in newBlocks) {
                        final id = const Uuid().v4();
                        _entries.add(MapEntry(id, block));
                        if (block.type == 'text') {
                          _controllers[id] = TextEditingController(text: block.data);
                        }
                      }
                      widget.onChanged(_entries.map((e) => e.value).toList());
                    });
                  },
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildBlock(MapEntry<String, ContentBlock> entry, int index, {bool dragging = false}) {
    final block = entry.value;
    final key = entry.key;

    if (block.type == 'text') {
      return Padding(
        key: ValueKey('text_$key'),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: TextBlockWidget(
          controller: _controllers[key]!,
          isEditing: widget.isEditing,
          onChanged: (value) {
            _entries[index] = MapEntry(key, ContentBlock(type: 'text', data: value));
            widget.onChanged(_entries.map((e) => e.value).toList());
          },
          onDelete: () {
            setState(() {
              _controllers.remove(key);
              _entries.removeAt(index);
              widget.onChanged(_entries.map((e) => e.value).toList());
            });
          },
        ),
      );
    } else if (block.type == 'image') {
      return Padding(
        key: ValueKey('image_$key'),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ImageBlockWidget(
          imageUrl: block.data,
          isEditing: widget.isEditing,
          onEdit: () async {
            try {
              final file = await ImageUploader.downloadImageFile(block.data);
              final newUrl = await ImageUploader.editAndReuploadImage(context, file, widget.logId);
              if (newUrl != null) {
                setState(() {
                  _entries[index] = MapEntry(key, ContentBlock(type: 'image', data: newUrl));
                  widget.onChanged(_entries.map((e) => e.value).toList());
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('이미지 편집 중 오류: \$e')),
              );
            }
          },
          onDelete: () {
            setState(() {
              _entries.removeAt(index);
              widget.onChanged(_entries.map((e) => e.value).toList());
            });
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}