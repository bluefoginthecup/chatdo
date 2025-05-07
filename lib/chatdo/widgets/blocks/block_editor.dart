import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/content_block.dart';
import '../../utils/image_uploader.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // listEquals 쓰려면 필요


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
  late List<MapEntry<String, ContentBlock>> _blockEntries;
  final Map<String, TextEditingController> _controllers = {};
  List<ContentBlock> getCurrentBlocks() {
    for (int i = 0; i < _blockEntries.length; i++) {
      final entry = _blockEntries[i];
      if (entry.value.type == 'text') {
        final controller = _controllers[entry.key];
        if (controller != null) {
          _blockEntries[i] = MapEntry(entry.key, ContentBlock(type: 'text', data: controller.text));
        }
      }
    }
    return _blockEntries.map((e) => e.value).toList();
  }

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
      _blockEntries.removeAt(index);
      widget.onChanged(_blockEntries.map((e) => e.value).toList());
    });
  }

  Widget _buildDeleteButton(int index) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("이 블록을 삭제하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeBlock(index);
                },
                child: const Text("삭제", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }

  Future<void> _selectImageSourceAndAdd() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final urls = await ImageUploader.pickAndUploadImages(
      context: context,
      fromCamera: source == 'camera',
    );

    if (urls.isEmpty) return;

    setState(() {
      for (final url in urls) {
        _blockEntries.add(
          MapEntry(Uuid().v4(), ContentBlock(type: 'image', data: url)),
        );
      }
      widget.onChanged(_blockEntries.map((e) => e.value).toList());
    });
  }

  Future<void> _editImageBlock(int index) async {
    final key = _blockEntries[index].key;
    final block = _blockEntries[index].value;
    final oldUrl = block.data;

    try {
      final file = await ImageUploader.downloadImageFile(oldUrl);
      debugPrint("편집용 이미지 파일 크기: \${await file.length()} bytes");

      final newUrl = await ImageUploader.editAndReuploadImage(
        context,
        file,
        widget.logId,
      );
      if (!mounted) return;
      if (newUrl != null) {
        setState(() {
          _blockEntries[index] =
              MapEntry(key, ContentBlock(type: 'image', data: newUrl));
        });
        widget.onChanged(_blockEntries.map((e) => e.value).toList());
        widget.onRequestSave?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지 편집 결과가 저장되지 않았습니다.")),
        );
      }
    } catch (e) {
      debugPrint('이미지 편집 중 에러: \$e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미지를 불러올 수 없습니다.")),
      );
    }
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
  void didUpdateWidget(covariant BlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 내용이 실제로 달라졌는지 확인
    if (!listEquals(widget.blocks, oldWidget.blocks)) {
      final uuid = const Uuid();
      final newEntries = widget.blocks.map((b) => MapEntry(uuid.v4(), b)).toList();

      // 기존 컨트롤러 재사용, 없는 것만 새로 만듦
      for (final entry in newEntries) {
        if (entry.value.type == 'text' && !_controllers.containsKey(entry.key)) {
          _controllers[entry.key] = TextEditingController(text: entry.value.data);
        }
      }

      setState(() {
        _blockEntries = newEntries;
      });
    }
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
                    child: Stack(
                      children: [
                        Container(
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
                        if (widget.isEditing)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildDeleteButton(i),
                          ),
                      ],
                    ),
                  ),
                ],
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                child: Text(
                  block.data,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }


          else if (block.type == 'image') {
            return ListTile(
              key: ValueKey(key),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isEditing)
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8.0, top: 12),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(block.data),
                        if (widget.isEditing)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _editImageBlock(i),
                              ),
                              _buildDeleteButton(i),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
        if (widget.isEditing)
          ListTile(
            key: const ValueKey("block-add-buttons"),
            title: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTextBlock,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('텍스트 추가'),
                ),
                ElevatedButton.icon(
                  onPressed: _selectImageSourceAndAdd,
                  icon: const Icon(Icons.image),
                  label: const Text('이미지 추가'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
