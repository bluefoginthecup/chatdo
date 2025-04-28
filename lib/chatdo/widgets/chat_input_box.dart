// chat_input_box.dart (multi_image_picker_plus 적용 최종 완성본)
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

enum Mode { todo, done }


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
  List<File> _pendingImages = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pendingImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingImages.length,
              itemBuilder: (context, index) => Stack(
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
              onPressed: _pickImagesFromGallery,
              onLongPress: _pickImageFromCamera,
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

  void _handleSubmit() async {
    if (_pendingImages.isNotEmpty) {
      await _handleSendImages(_pendingImages, widget.controller.text.trim());
      setState(() {
        _pendingImages.clear();
        widget.controller.clear();
      });
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onSubmitted(text, Mode.todo, DateTime.now());
    widget.controller.clear();
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
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _pendingImages.add(File(picked.path));
      });
    }
  }

  Future<void> _handleSendImages(List<File> images, String title) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    List<String> downloadUrls = [];

    for (var imageFile in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('chat_images').child(userId).child(fileName);
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(userId).collection('logs').doc();

    final entry = ScheduleEntry(
      content: title.isNotEmpty ? title : '[IMAGES]',
      date: now,
      type: ScheduleType.todo,
      createdAt: now,
      docId: docRef.id,
      imageUrl: downloadUrls.first, // 대표 이미지만 사용
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
