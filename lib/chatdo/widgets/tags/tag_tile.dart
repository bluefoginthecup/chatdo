import 'package:flutter/material.dart';
import '/chatdo/models/user_tag.dart';

class TagTile extends StatelessWidget {
  final UserTag tag;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

  const TagTile({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onSelect,
    this.onToggleFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(tag.name),
            selected: isSelected,
            onSelected: (_) => onSelect?.call(),
            selectedColor: Colors.orange,
            backgroundColor: tag.isFavorite ? Colors.amber[100] : Colors.grey[200],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              tag.isFavorite ? Icons.star : Icons.star_border,
              color: tag.isFavorite ? Colors.amber : Colors.grey,
              size: 20,
            ),
            onPressed: onToggleFavorite,
            tooltip: '즐겨찾기',
          ),
          if (!tag.isBuiltin)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: '삭제',
            ),
        ],
      ),
    );
  }
}
