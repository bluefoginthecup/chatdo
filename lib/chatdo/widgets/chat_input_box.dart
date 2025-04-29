// chat_input_box.dart (태그 선택 모달 방식 적용 + 기존 기능 유지)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../usecases/schedule_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/game/core/game_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

enum Mode { todo, done }
enum DateTag { today, tomorrow, yesterday }
class ChatInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String text, Mode mode, DateTime date, List<String> tags) onSubmitted;
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

  List<File> _pendingImages = [];
  List<String> _selectedTags = [];
  final List<String> _availableTags = ['운동', '공부', '일', '건강', '기타'];
  Mode _selectedMode = Mode.todo;
  DateTag? _selectedDateTag;
  bool _isSending = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => _showDateModal(Mode.todo),
              child: const Text('할일'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _showDateModal(Mode.done),
              child: const Text('한일'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _showTagModal,
              child: const Text('태그'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (_pendingImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingImages.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final item = _pendingImages.removeAt(oldIndex);
                  _pendingImages.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) => Stack(
                key: ValueKey(_pendingImages[index]),
                children: [
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: Image.file(_pendingImages[index], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pendingImages.removeAt(index);
                        });
                      },
                      child: Container(
                        color: Colors.black54,
                        child: const Icon(Icons.close, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _pickImageFromCamera,
              onLongPress: _pickImagesFromGallery,
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
            _isSending
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14)),
            )
                : IconButton(
              icon: const Icon(Icons.send),
              color: Colors.teal,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ],
    );
  }

  void _showTagModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    isSelected ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDateModal(Mode mode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final List<MapEntry<DateTag, String>> options = mode == Mode.todo
            ? [
          MapEntry(DateTag.today, '오늘'),
          MapEntry(DateTag.tomorrow, '내일'),
          MapEntry(DateTag.yesterday, '날짜선택'),
        ]
            : [
          MapEntry(DateTag.today, '오늘'),
          MapEntry(DateTag.yesterday, '어제'),
          MapEntry(DateTag.yesterday, '날짜선택'),
        ];
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: options.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedDateTag = entry.key;
                    _selectedMode = mode;
                  });
                  Navigator.pop(context);
                },
                child: Text(entry.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _handleSubmit() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _selectedDateTag == null) return;
    final resolvedDate = _resolveDate(_selectedDateTag!);
    if (_pendingImages.isNotEmpty) {
      await _handleSendImages(List<File>.from(_pendingImages), text);
    } else {
      widget.onSubmitted(text, _selectedMode, resolvedDate, List<String>.from(_selectedTags));
    }
    setState(() {
      widget.controller.clear();
      _pendingImages.clear();
      _selectedTags.clear();
      _selectedDateTag = null;
    });
  }

  DateTime _resolveDate(DateTag tag) {
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

  void _pickImagesFromGallery() async {
    final resultList = await MultiImagePicker.pickImages();
    for (var asset in resultList) {
      final byteData = await asset.getByteData();
      final tempDir = Directory.systemTemp;
      final tempFile = await File('${tempDir.path}/${asset.name}').writeAsBytes(byteData.buffer.asUint8List());
      setState(() {
        _pendingImages.add(tempFile);
      });
    }
  }

  void _pickImageFromCamera() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      final File file = File(picked.path);
      setState(() {
        _pendingImages.add(file);
      });
    }
  }

  Future<void> _handleSendImages(List<File> images, String title) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    List<String> downloadUrls = [];

    int totalBytes = 0;
    for (var imageFile in images) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.webp';
      final ref = FirebaseStorage.instance.ref().child('chat_images').child(userId).child(fileName);
      final tempDir = Directory.systemTemp;
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${tempDir.path}/compressed_$fileName',
        quality: 70,
        minWidth: 720,
        minHeight: 720,
        format: CompressFormat.webp,
      );
      final File? compressedFile = compressedXFile != null ? File(compressedXFile.path) : null;
      final File fileToUpload = compressedFile ?? imageFile;
      final fileSize = await fileToUpload.length();
      totalBytes += fileSize;

      final metadata = SettableMetadata(contentType: 'image/webp');
      UploadTask uploadTask = ref.putFile(fileToUpload, metadata);
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(userId).collection('logs').doc();
    final entry = ScheduleEntry(
      content: title.isNotEmpty ? title : '[IMAGES]',
      date: _resolveDate(_selectedDateTag!),
      type: _selectedMode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      docId: docRef.id,
      imageUrl: downloadUrls.isNotEmpty ? downloadUrls.first : null,
      imageUrls: downloadUrls,
      body: null,
    );

    await ScheduleUseCase.updateEntry(
      entry: entry,
      newType: entry.type,
      provider: context.read<ScheduleProvider>(),
      gameController: widget.gameController,
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
  }
}
