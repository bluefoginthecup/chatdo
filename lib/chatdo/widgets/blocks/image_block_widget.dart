// image_block_widget.dart
import 'package:flutter/material.dart';

class ImageBlockWidget extends StatelessWidget {
  final String imageUrl;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? dragHandle;

  const ImageBlockWidget({
    super.key,
    required this.imageUrl,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing && dragHandle != null) dragHandle!,
        Expanded(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Image.network(imageUrl),
              if (isEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: onEdit,
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}