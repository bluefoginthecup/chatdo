// chat_input_box.dart (로딩 스피너 추가 최종 수정본)
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
import 'tag_selector.dart';
import '../models/enums.dart'; // Mode, Dat
import '../widgets/mode_date_selector.dart';


class ChatInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String text, Mode mode, DateTime, List<String>) onSubmitted;
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
  List<String> _selectedTags = [];
  List<File> _pendingImages = [];
  Mode _selectedMode = Mode.todo;
  DateTime _selectedDate = DateTime.now();
  bool _isSending = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ModeDateSelector(
                selectedMode: _selectedMode,
                selectedDate: _selectedDate,
                onModeChanged: (mode) => setState(() => _selectedMode = mode),
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
            ),
            const SizedBox(width: 8),
            TagSelector(
              initialSelectedTags: _selectedTags,
              onTagChanged: (selectedTags) {
                setState(() {
                  _selectedTags = selectedTags;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

// ✅ 선택된 태그가 있을 때만 Chip 보여주기
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _selectedTags.remove(tag);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
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
        const SizedBox(height: 4),
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


  void _handleSubmit() async {
    if (_pendingImages.isNotEmpty) {
      setState(() {
        _isSending = true;
      });
      await _handleSendImages(List<File>.from(_pendingImages), widget.controller.text.trim());
      setState(() {
        _pendingImages.clear();
        widget.controller.clear();
        _isSending = false;
      });

      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
    });
    widget.onSubmitted(text, _selectedMode, _selectedDate, _selectedTags);
    setState(() {
      widget.controller.clear();
      _selectedTags.clear();
      _isSending = false;
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
      final fileName = '$timestamp.jpg';
      final ref = FirebaseStorage.instance.ref().child('chat_images').child(userId).child(fileName);
      final tempDir = Directory.systemTemp;
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${tempDir.path}/compressed_$fileName',
        quality: 70,
        minWidth: 720,
        minHeight: 720,
        format: CompressFormat.jpeg,
      );
      final File? compressedFile = compressedXFile != null ? File(compressedXFile.path) : null;
      final int originalSize = await imageFile.length();
      final int compressedSize = compressedFile != null ? await compressedFile.length() : originalSize;
      print('📦 원본 크기: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
      print('📦 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');
      final File fileToUpload = compressedFile ?? imageFile;
      final fileSize = await fileToUpload.length();
      totalBytes += fileSize;
      final metadata = SettableMetadata(contentType: 'image/jpeg');
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

    final readable = (totalBytes < 1024)
        ? '$totalBytes B'
        : (totalBytes < 1024 * 1024)
        ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
        : '${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('메시지 전송 완료 (총 $readable)'), duration: Duration(seconds: 2)),
    );



    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(userId).collection('logs').doc();

    final entry = ScheduleEntry(
      content: title.isNotEmpty ? title : '[IMAGES]',
      date: _selectedDate,
      type: _selectedMode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      docId: docRef.id,
      imageUrl: downloadUrls.isNotEmpty ? downloadUrls.first : null,
      imageUrls: downloadUrls,
      body: null,
      tags: _selectedTags,
      timestamp: DateTime.now(),
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
      imageUrls: entry.imageUrls,
    ));
  }
}
