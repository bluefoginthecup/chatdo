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
  Mode _selectedMode = Mode.todo;
  DateTag _selectedDateTag = DateTag.today;
  bool _isSending = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 날짜 버튼
        Wrap(
          spacing: 8,
          children: _buildDateButtons(),
        ),

        const SizedBox(height: 8),

        // 모드 버튼
        Wrap(
          spacing: 8,
          children: [
            _buildModeButton(Mode.todo, '할일'),
            _buildModeButton(Mode.done, '한일'),
          ],
        ),

        const SizedBox(height: 8),

        // 선택된 태그 칩
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _selectedTags.map((tag) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                },
                child: Chip(
                  label: Text('$tag ❌'), // ❌ 붙여서 보여줌
                  backgroundColor: Colors.teal.shade50,
                ),
              );
            }).toList(),
          ),

        // ✨ 태그 추가 버튼
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _showTagSelectionSheet, // 모달 띄우는 함수
            icon: Icon(Icons.add),
            label: const Text('태그 추가'),
          ),
        ),

        const SizedBox(height: 8),

        // 메시지 입력창 + 보내기 버튼
        Row(
          children: [
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
    widget.onSubmitted(text, _selectedMode, _resolveDate(_selectedDateTag), _selectedTags);

    setState(() {
      widget.controller.clear();
      _isSending = false;
    });
  }

  void _showTagSelectionSheet() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedTags);
        TextEditingController tagController = TextEditingController();
        List<String> availableTags = ['할일앱', '개발', '운동', '공부', '건강', '취미', '여행'];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tagController,
                    decoration: const InputDecoration(
                      labelText: '새 태그 입력',
                      suffixIcon: Icon(Icons.add),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && !availableTags.contains(value.trim())) {
                        setModalState(() {
                          availableTags.add(value.trim());
                          tempSelected.add(value.trim());
                          tagController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: availableTags.map((tag) {
                        final isSelected = tempSelected.contains(tag);
                        return ListTile(
                          title: Text(tag),
                          trailing: isSelected ? const Icon(Icons.check) : null,
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.remove(tag);
                              } else {
                                tempSelected.add(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, tempSelected);
                    },
                    child: const Text('완료'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedTags = selected;
      });
    }
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
      tags: _selectedTags,
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
      tags: entry.tags,
    ));
  }
}
