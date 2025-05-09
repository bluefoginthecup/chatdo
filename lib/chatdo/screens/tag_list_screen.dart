import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_tag.dart';
import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../widgets/tags/tag_tile.dart';
import '../data/tag_repository.dart';
import '/game/core/game_controller.dart';

class TagListScreen extends StatefulWidget {
  final GameController gameController;

  const TagListScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  List<UserTag> _tags = [];
  String? _selectedTag;
  List<ScheduleEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTagsAndEntries();
  }

  Future<void> _loadTagsAndEntries() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tags = await TagRepository.loadAllTags(uid);
    setState(() {
      _tags = tags;
      if (_selectedTag == null && tags.isNotEmpty) {
        _selectedTag = tags.first.name;
      }
    });

    if (_selectedTag != null) {
      _loadEntries(_selectedTag!);
    }
  }

  Future<void> _loadEntries(String tagName) async {
    setState(() {
      _isLoading = true;
      _selectedTag = tagName;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(uid)
          .collection('logs')
          .where('tags', arrayContains: tagName)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      setState(() {
        _entries = snapshot.docs.map((doc) => ScheduleEntry.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('🔥 태그 일정 불러오기 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite(UserTag tag) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updated = tag.copyWith(isFavorite: !tag.isFavorite);
    await TagRepository.saveTag(uid, updated);

    setState(() {
      final index = _tags.indexWhere((t) => t.name == tag.name);
      if (index != -1) _tags[index] = updated;
    });
  }

  Future<void> _deleteTag(UserTag tag) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || tag.isBuiltin) return;

    await TagRepository.deleteTag(uid, tag.name);

    setState(() {
      _tags.removeWhere((t) => t.name == tag.name);
      if (_selectedTag == tag.name && _tags.isNotEmpty) {
        _selectedTag = _tags.first.name;
        _loadEntries(_selectedTag!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _tags.map((tag) {
            return TagTile(
              tag: tag,
              isSelected: _selectedTag == tag.name,
              onSelect: () => _loadEntries(tag.name),
              onToggleFavorite: () => _toggleFavorite(tag),
              onDelete: () => _deleteTag(tag),
            );
          }).toList(),
        ),
        const Divider(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
              ? const Center(child: Text('해당 태그의 일정이 없습니다'))
              : ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              return ScheduleEntryTile(
                entry: _entries[index],
                gameController: widget.gameController,
                onRefresh: () => _loadEntries(_selectedTag!),
              );
            },
          ),
        ),
      ],
    );
  }
}
