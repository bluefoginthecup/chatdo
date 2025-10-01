import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_tag.dart';
import '../widgets/tags/tag_tile.dart';
import '../data/tag_repository.dart';
import '../widgets/tags/custom_tag_dialog.dart';
import '/game/core/game_controller.dart';

class TagManagementScreen extends StatefulWidget {
  final GameController gameController;
  const TagManagementScreen({super.key, required this.gameController});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  List<UserTag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tags = await TagRepository.loadAllTags(uid);
    setState(() => _tags = tags);
  }

  Future<void> _toggleFavorite(UserTag tag) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updated = tag.copyWith(isFavorite: !tag.isFavorite);
    await TagRepository.saveTag(uid, updated);
    _loadTags();
  }

  Future<void> _deleteTag(UserTag tag) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || tag.isBuiltin) return;

    await TagRepository.deleteTag(uid, tag.name);
    _loadTags();
  }

  Future<void> _addNewTag() async {
    final newTagName = await showCustomTagDialog(context);
    final cleaned = newTagName?.trim();
    if (cleaned == null || cleaned.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final exists = _tags.any((t) =>
    t.name.toLowerCase() == cleaned.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 존재하는 태그입니다')),
      );
      return;
    }

    final newTag = UserTag(name: cleaned, isFavorite: false, isBuiltin: false);
    await TagRepository.saveTag(uid, newTag);
    _loadTags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _tags.map((tag) {
          return TagTile(
            tag: tag,
            isSelected: false,
            onToggleFavorite: () => _toggleFavorite(tag),
            onDelete: () => _deleteTag(tag),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('태그 추가'),
        onPressed: _addNewTag,
      ),
    );
  }
}
