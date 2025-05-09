// lib/chatdo/widgets/image_upload_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/upload_item.dart';

class ImageUploadPreview extends StatelessWidget {
  final List<UploadItem> items;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index)? onRetry;

  const ImageUploadPreview({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onReorder,
    this.onRetry,
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
              if (item.hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.redAccent),
                        onPressed: () => onRetry?.call(index),
                      ),
                    ),
                  ),
                )
              else if (item.isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: item.progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.black26,
                          color: Colors.tealAccent,
                        ),
                        Text(
                          '${(item.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
