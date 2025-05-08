// select_image_and_add.dart
import 'package:flutter/material.dart';
import '../../utils/image_uploader.dart';
import '../../models/content_block.dart';
import 'package:uuid/uuid.dart';

class SelectImageAndAdd extends StatelessWidget {
  final void Function(List<ContentBlock>) onImagesAdded;
  final String logId;

  const SelectImageAndAdd({
    super.key,
    required this.onImagesAdded,
    required this.logId,
  });

  Future<void> _selectImageSourceAndAdd(BuildContext context) async {
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

    final blocks = urls.map((url) => ContentBlock(type: 'image', data: url)).toList();
    onImagesAdded(blocks);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _selectImageSourceAndAdd(context),
      icon: const Icon(Icons.image),
      label: const Text('이미지 추가'),
    );
  }
}
