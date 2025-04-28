// chat_input_box.dart (개선 버전)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../usecases/schedule_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/game/core/game_controller.dart';

enum Mode { todo, done }
enum DateTag { today, tomorrow, yesterday }

class ChatInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String text, Mode mode, DateTime date) onSubmitted;
  final GameController gameController;

  const ChatInputBox({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.gameController,
    this.focusNode,
  });

  @override
  State<ChatInputBox> createState() => _ChatInputBoxState();
}

class _ChatInputBoxState extends State<ChatInputBox> {
  Mode? _selectedMode = Mode.todo;
  DateTag? _selectedDateTag = DateTag.today;

  List<DateTag> get currentDateOptions => _selectedMode == Mode.todo
      ? [DateTag.today, DateTag.tomorrow]
      : [DateTag.today, DateTag.yesterday];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: _selectedMode == null
              ? [_buildModeButton(Mode.todo, '할일'), const SizedBox(width: 8), _buildModeButton(Mode.done, '한일')]
              : currentDateOptions.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildDateButton(tag),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _pickImageFromCamera,
              onLongPress: _showPickOptions,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onSubmitted: (_) => _handleSubmit(),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.teal,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ],
    );
  }

  void _handleSubmit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _selectedMode == null || _selectedDateTag == null) return;
    FocusScope.of(context).unfocus();
    widget.onSubmitted(text, _selectedMode!, resolveDate(_selectedDateTag!));
    widget.controller.clear();
  }

  void _pickImageFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      await _handleSendImage(File(picked.path));
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('사진에서 선택'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (picked != null) {
                await _handleSendImage(File(picked.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('파일 선택'),
            onTap: () {
              // 파일 선택 로직 추가 가능
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendImage(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('chat_images').child(userId).child(fileName);

    try {
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      final titleController = TextEditingController();
      final bodyController = TextEditingController();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('제목과 내용을 입력하세요'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: '제목')),
              TextField(controller: bodyController, decoration: const InputDecoration(labelText: '내용')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
          ],
        ),
      );
      if (confirmed != true) return;

      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      final now = DateTime.now();
      final docRef = FirebaseFirestore.instance.collection('messages').doc(userId).collection('logs').doc();

      final entry = ScheduleEntry(
        content: title.isNotEmpty ? title : '[IMAGE]',
        date: resolveDate(_selectedDateTag ?? DateTag.today),
        type: _selectedMode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
        createdAt: now,
        docId: docRef.id,
        imageUrl: downloadUrl,
        body: body.isNotEmpty ? body : null,
      );

      await ScheduleUseCase.updateEntry(
        entry: entry,
        newType: entry.type,
        provider: context.read<ScheduleProvider>(),
        gameController: widget.gameController, // 필요시 수정
        firestore: FirebaseFirestore.instance,
        userId: userId,
      );

      final box = await Hive.openBox<Message>('messages');
      await box.add(Message(
        id: entry.docId ?? UniqueKey().toString(),
        text: entry.content,
        type: entry.type.name,
        date: DateFormat('yyyy-MM-dd').format(entry.date),
        timestamp: now.millisecondsSinceEpoch,
        imageUrl: entry.imageUrl,
      ));

    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
    }
  }

  String getDateTagLabel(DateTag tag) {
    switch (tag) {
      case DateTag.today:
        return '오늘';
      case DateTag.tomorrow:
        return '내일';
      case DateTag.yesterday:
        return '어제';
    }
  }

  DateTime resolveDate(DateTag tag) {
    final now = DateTime.now();
    switch (tag) {
      case DateTag.today:
        return now;
      case DateTag.tomorrow:
        return now.add(const Duration(days: 1));
      case DateTag.yesterday:
        return now.subtract(const Duration(days: 1));
    }
  }

  ButtonStyle _buttonStyle({required bool isSelected, required Color baseColor}) {
    return OutlinedButton.styleFrom(
      backgroundColor: isSelected ? Colors.teal.shade100 : baseColor,
      side: BorderSide(color: isSelected ? Colors.teal : Colors.grey),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildModeButton(Mode mode, String label) {
    final bool isSelected = _selectedMode == mode;
    final Color baseColor = Colors.amber.shade100;

    return OutlinedButton(
      onPressed: () async {
        setState(() {
          _selectedMode = mode;
          _selectedDateTag = null;
        });
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() {});
      },
      style: _buttonStyle(isSelected: isSelected, baseColor: baseColor),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.teal.shade900 : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDateButton(DateTag tag) {
    final bool isSelected = _selectedDateTag == tag;
    final Color baseColor = Colors.teal.shade50;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (_selectedDateTag == tag) {
            _selectedDateTag = null;
            _selectedMode = null;
          } else {
            _selectedDateTag = tag;
          }
        });
      },
      style: _buttonStyle(isSelected: isSelected, baseColor: baseColor),
      child: Text(
        getDateTagLabel(tag),
        style: TextStyle(
          color: isSelected ? Colors.teal.shade900 : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
