import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/routine_model.dart';
import '../models/schedule_entry.dart';
import '../models/content_block.dart';
import '../services/routine_service.dart';
import '../widgets/routine_edit_form.dart';
import '../widgets/blocks/block_editor.dart';
import '../../game/core/game_controller.dart';
import '../widgets/tag_selector.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final Future<void> Function()? onUpdate;

  const ScheduleDetailScreen({
    Key? key,
    required this.entry,
    required this.gameController,
    this.onUpdate,
  }) : super(key: key);

  @override
  _ScheduleDetailScreenState createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late ScheduleEntry _entry;
  late TextEditingController _titleController;
  bool _isEditing = false;
  bool _isRoutineFormOpen = false;

  List<ContentBlock> _blocks = [];
  List<String> _selectedTags = [];

  final ImagePicker _picker = ImagePicker();
  final GlobalKey<BlockEditorState> _blockEditorKey = GlobalKey<BlockEditorState>();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _titleController = TextEditingController(text: _entry.content);
    _selectedTags = List.from(_entry.tags);

    _fetchLatestEntry(); // 🔥 여기에 Firestore fetch 추가
  }

  Future<void> _fetchLatestEntry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(widget.entry.docId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final raw = data['body'] ?? '[]';

    try {
      List<ContentBlock> parsedBlocks = [];

      final decoded = jsonDecode(raw);

      if (decoded is List) {
        parsedBlocks = decoded.map((e) => ContentBlock.fromJson(e)).toList();
      } else if (decoded is String) {
        final inner = jsonDecode(decoded);
        if (inner is List) {
          parsedBlocks = inner.map((e) => ContentBlock.fromJson(e)).toList();
        }
      }

      setState(() {
        _entry = _entry.copyWith(
          content: data['content'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          imageUrls: List<String>.from(data['imageUrls'] ?? []),
          body: raw,
        );
        _blocks = parsedBlocks;
      });
    } catch (e) {
      debugPrint('🚨 [_fetchLatestEntry] 디코딩 실패: $e');
      setState(() {
        _blocks = [ContentBlock(type: 'text', data: raw)];
      });
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    debugPrint("🧪 [_saveChanges] 시작");
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    final currentBlocks = _blockEditorKey.currentState?.getCurrentBlocks() ?? [];
    debugPrint("📦 currentBlocks: $currentBlocks");
    final encodedBody = jsonEncode(currentBlocks.map((e) => e.toJson()).toList());
    debugPrint("📝 encodedBody: $encodedBody");

    final previousImagesEmpty = _entry.imageUrls == null || _entry.imageUrls!.isEmpty;
    final newImages = currentBlocks.where((e) => e.type == 'image').map((e) => e.data).toList();
    final isFirstImageAdded = previousImagesEmpty && newImages.isNotEmpty;

    final imageUrlsToSave = isFirstImageAdded ? [newImages.first] : newImages;

    debugPrint("📤 Firestore 업데이트 시작");
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'content': _titleController.text.trim(),
      'body': encodedBody,
      'tags': _selectedTags,
      'imageUrls': imageUrlsToSave,
    });

    setState(() {
      _entry = _entry.copyWith(
        content: _titleController.text.trim(),
        body: encodedBody,
        imageUrls: imageUrlsToSave,
        timestamp: DateTime.now(),
      );
      _blocks = currentBlocks;
      _isEditing = false;
    });

    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }

    debugPrint("✅ 저장 완료 후 UI 업데이트 및 알림");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('할일이 수정되었습니다!')),
    );
  }

  Future<void> _updateDate(DateTime newDate) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    final dateString = "${newDate.year.toString().padLeft(4, '0')}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({'date': dateString});

    setState(() {
      _entry = _entry.copyWith(date: newDate);
    });
    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }
  }

  Future<void> _deleteEntry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_entry.docId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('이 할일을 정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(userId)
          .collection('logs')
          .doc(_entry.docId)
          .delete();

      if (widget.onUpdate != null) {
        await widget.onUpdate!();
      }

      Navigator.pop(context);
    }
  }

  Future<void> _saveRoutine(Map<String, String> selectedDays) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('daily_routines').doc();

    final routine = Routine(
      docId: docRef.id,
      title: _entry.content,
      days: selectedDays,
      userId: userId,
      createdAt: DateTime.now(),
    );

    await RoutineService.saveRoutine(routine);

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'routineInfo': {
        'docId': routine.docId,
        'days': routine.days,
      }
    });

    widget.gameController.addPoints(10);

    if (widget.onUpdate != null) {
      await widget.onUpdate!();
    }

    setState(() {
      _entry = _entry.copyWith(
        routineInfo: {
          'docId': routine.docId,
          'days': routine.days,
        },
      );
      _isRoutineFormOpen = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('루틴이 저장되었습니다! 포인트 추가!')),
    );
  }

  Future<void> _logAndSaveChanges() async {
    final stopwatch = Stopwatch()..start();
    debugPrint("⏱ 저장 시작");

    await _saveChanges();

    stopwatch.stop();
    debugPrint("⏱ 저장 완료: ${stopwatch.elapsedMilliseconds}ms");

    if (stopwatch.elapsedMilliseconds > 1500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 완료 (${stopwatch.elapsedMilliseconds}ms)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.red),
              onPressed: _logAndSaveChanges,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_entry.date.year}-${_entry.date.month.toString().padLeft(2, '0')}-${_entry.date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _entry.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        await _updateDate(picked);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _isEditing
                ? TextField(controller: _titleController, decoration: const InputDecoration(labelText: '제목'))
                : Text(_entry.content, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            BlockEditor(
              key: _blockEditorKey,
              blocks: _blocks,
              isEditing: _isEditing,
              onChanged: (updated) {
                _blocks = updated; // setState() 제거 → rebuild 최소화
              },

              logId: _entry.docId!,
              onRequestSave: _logAndSaveChanges,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isRoutineFormOpen = !_isRoutineFormOpen;
                });
              },
              icon: const Icon(Icons.repeat),
              label: const Text('루틴 등록'),
            ),
            const SizedBox(height: 12),
            if (_isRoutineFormOpen)
              RoutineEditForm(
                initialDays: _entry.routineInfo?['days']?.cast<String, String>(),
                onSave: _saveRoutine,
              ),
            const SizedBox(height: 24),
            if (_entry.routineInfo != null) _buildRoutineInfo(),
            if (_isEditing || _selectedTags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '태그',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      if (_isEditing)
                        TagSelector(
                          initialSelectedTags: _selectedTags,
                          onTagChanged: (tags) {
                            setState(() {
                              _selectedTags = tags;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedTags
                        .map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: _isEditing
                          ? () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                      }
                          : null,
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineInfo() {
    final daysMap = (_entry.routineInfo!['days'] as Map).cast<String, String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('루틴 등록됨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...daysMap.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
      ],
    );
  }
}
