import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_tag.dart';
import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../data/tag_repository.dart';
import '/game/core/game_controller.dart';

class TagLogScreen extends StatefulWidget {
  final GameController gameController;
  const TagLogScreen({super.key, required this.gameController});

  @override
  State<TagLogScreen> createState() => _TagLogScreenState();
}

class _TagLogScreenState extends State<TagLogScreen> {
  List<UserTag> _tags = [];
  String? _selectedTag;
  List<ScheduleEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tags = await TagRepository.loadAllTags(uid);
    setState(() {
      _tags = tags;
      _selectedTag = tags.isNotEmpty ? tags.first.name : null;
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

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('tags', arrayContains: tagName)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    setState(() {
      _entries =
          snapshot.docs.map((doc) => ScheduleEntry.fromFirestore(doc)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tags.map((tag) {
              final isSelected = tag.name == _selectedTag;
              return ChoiceChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (_) => _loadEntries(tag.name),
                selectedColor: Colors.orange,
                backgroundColor: tag.isFavorite ? Colors.amber[100] : Colors
                    .grey[200],
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