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
  List<File> _pendingImages = [];
  Mode _selectedMode = Mode.todo;
  DateTag _selectedDateTag = DateTag.today;
  bool _isSending = false;
  double _uploadProgress = 0.0;
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTag != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_selectedTag',
                        style: const TextStyle(fontSize: 14, color: Colors.teal),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTag = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            _buildModeButton(Mode.todo, '할일'),
            const SizedBox(width: 8),
            _buildModeButton(Mode.done, '한일'),
            const SizedBox(width: 8),
            TagSelector(
              onTagSelected: (tag) {
                setState(() {
                  _selectedTag = tag;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _buildDateButtons(),
        ),
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

  Widget _buildModeButton(Mode mode, String label) {
    final isSelected = _selectedMode == mode;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMode = mode),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal.shade100 : null,
      ),
      child: Text(label),
    );
  }

  List<Widget> _buildDateButtons() {
    final options = _selectedMode == Mode.todo
        ? [DateTag.today, DateTag.tomorrow]
        : [DateTag.today, DateTag.yesterday];

    return options.map((tag) {
      final isSelected = _selectedDateTag == tag;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton(
          onPressed: () => setState(() => _selectedDateTag = tag),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? Colors.teal.shade100 : null,
          ),
          child: Text(_getDateLabel(tag)),
        ),
      );
    }).toList();
  }

  String _getDateLabel(DateTag tag) {
    switch (tag) {
      case DateTag.today:
        return '오늘';
      case DateTag.tomorrow:
        return '내일';
      case DateTag.yesterday:
        return '어제';
    }
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

      // ✅ 여기 스낵바 추가
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지 전송 완료'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
    });
    widget.onSubmitted(text, _selectedMode, _resolveDate(_selectedDateTag));
    setState(() {
      widget.controller.clear();
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
      final File file = File(picked.path); // XFile → File 변환
      setState(() {
        _pendingImages.add(file); // File을 리스트에 저장
      });
    }
  }


  Future<void> _handleSendImages(List<File> images, String title) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    List<String> downloadUrls = [];

    int totalBytes = 0;
    for (var imageFile in images) {

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.webp';  // 무조건 .jpg

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


      // 📢 추가: 압축 전후 용량 출력
      final int originalSize = await imageFile.length();
      final int compressedSize = compressedFile != null ? await compressedFile.length() : originalSize;

      print('📦 원본 크기: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
      print('📦 압축 후 크기: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');


      final File fileToUpload = compressedFile ?? imageFile;
      final fileSize = await fileToUpload.length(); // 📢 압축된 파일 사이즈를 합산
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

    String readableSize(int bytes) {
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
      }
    }

// 그리고 사용
    final readable = readableSize(totalBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('메시지 전송 완료 (총 $readable)'), duration: Duration(seconds: 2)),
    );



    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(userId).collection('logs').doc();

    final entry = ScheduleEntry(
      content: title.isNotEmpty ? title : '[IMAGES]',
      date: _resolveDate(_selectedDateTag),
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
