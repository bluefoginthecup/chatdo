import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../models/content_block.dart';
import '../widgets/block_editor.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleEntry entry;

  const ScheduleDetailScreen({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late ScheduleEntry _entry;
  late List<ContentBlock> _blocks;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    try {
      final decoded = jsonDecode(_entry.body ?? '[]') as List;
      _blocks = decoded.map((e) => ContentBlock.fromJson(e)).toList();
    } catch (_) {
      // entry.content과 imageUrls도 block으로 흡수
      _blocks = [];
      if (_entry.content.trim().isNotEmpty) {
        _blocks.add(ContentBlock(type: 'text', data: _entry.content));
      }
      if (_entry.imageUrls != null) {
        _blocks.addAll(_entry.imageUrls!.map((url) => ContentBlock(type: 'image', data: url)));
      }
    }
  }

  void _saveChanges() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final encodedBody = jsonEncode(_blocks.map((e) => e.toJson()).toList());

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(userId)
        .collection('logs')
        .doc(_entry.docId)
        .update({
      'content': _blocks.isNotEmpty && _blocks.first.type == 'text' ? _blocks.first.data : '',
      'body': encodedBody,
    });

    setState(() {
      _entry = _entry.copyWith(
        content: _blocks.isNotEmpty && _blocks.first.type == 'text' ? _blocks.first.data : '',
        body: encodedBody,
      );
      _isEditing = false;
    });
  }

  void _addImageBlock() {
    // TODO: implement actual image picking and upload
    setState(() {
      _blocks.add(ContentBlock(type: 'image', data: 'https://via.placeholder.com/150'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                      setState(() {
                        _entry = _entry.copyWith(date: picked);
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          BlockEditor(
            blocks: _blocks,
            isEditing: _isEditing,
            onChanged: (updated) => _blocks = updated,
            onImageAdd: _addImageBlock,
          ),
        ],
      ),
    );
  }
}
