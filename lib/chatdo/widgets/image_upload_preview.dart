// lib/chatdo/widgets/image_upload_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/upload_item.dart'; // ← 상대 경로 맞춰서 import



class ImageUploadPreview extends StatelessWidget {
  final List<UploadItem> items;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ImageUploadPreview({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        onReorder: onReorder,
        itemBuilder: (context, index) {
          final item = items[index];
          return Stack(
            key: ValueKey(item.file),
            children: [
              Container(
                margin: const EdgeInsets.all(4),
                child: Image.file(
                  item.file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              if (item.isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(value: item.progress),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    color: Colors.black54,
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
