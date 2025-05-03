// 태그 기반 일정 로그 뷰 (최신순으로 스크롤)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '/game/core/game_controller.dart';
import '../constants/tag_list.dart';

class TagListScreen extends StatefulWidget {
  final GameController gameController;

  const TagListScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  String? _selectedTag;
  List<ScheduleEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (allTags.isNotEmpty) {
      _loadEntries(allTags.first);
    }
  }

  Future<void> _loadEntries(String tag) async {
    setState(() {
      _isLoading = true;
      _selectedTag = tag;
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
          .where('tags', arrayContains: tag)
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = _selectedTag == tag;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _loadEntries(tag),
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
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
