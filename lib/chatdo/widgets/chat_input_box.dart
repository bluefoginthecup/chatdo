// chat_input_box.dart (로딩스피너 개별 이미지용 리팩터)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';
import 'package:image_picker/image_picker.dart';
import '/game/core/game_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'tags/tag_selector.dart';
import '../models/enums.dart';
import '../widgets/mode_date_selector.dart';
import '../utils/image_source_selector.dart';
import '../widgets/image_upload_preview.dart';
import '../models/upload_item.dart';
import '../features/text_dictionary/custom_typeahead_textfield.dart';
import '../data/firestore/repos/text_dictionary_repo.dart';



class ChatInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(
      String text,
      Mode mode,
      DateTime date,
      List<String> tags, {
      List<String> localPaths,
      })  onSubmitted;
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
  List<UploadItem> _pendingUploads = [];
  Mode _selectedMode = Mode.todo;
  DateTime _selectedDate = DateTime.now();
  bool _isSending = false;
  List<String> _dictionary = [];
  bool _dictionaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final dict = await TextDictionaryRepo.load();
    setState(() {
      _dictionary = dict;
      _dictionaryLoaded = true;
    });
  }


  void _showImageSourceSelector() async {
    final source = await showImageSourceModal(context);
    if (source == 'camera') {
      _pickImageFromCamera();
    } else if (source == 'gallery') {
      _pickImagesFromGallery();
    }
  }

  void _pickImageFromCamera() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      final File file = File(picked.path);
      setState(() {
        _pendingUploads.add(UploadItem(file: file));
      });
    }
  }

  void _pickImagesFromGallery() async {
    final resultList = await MultiImagePicker.pickImages();
    for (var asset in resultList) {
      final byteData = await asset.getByteData();
      final tempDir = Directory.systemTemp;
      final tempFile = await File('${tempDir.path}/${asset.name}').writeAsBytes(byteData.buffer.asUint8List());
      setState(() {
        _pendingUploads.add(UploadItem(file: tempFile));
      });
    }
  }
  Future<void> _handleSubmit() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty && _pendingUploads.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    // ✅ 로컬 파일 경로만 추출해서 넘김
    final paths = _pendingUploads.map((e) => e.file.path).toList();

    widget.onSubmitted(
      text,
      _selectedMode,
      _selectedDate,
      _selectedTags,
      localPaths: paths,
    );

    setState(() {
      _pendingUploads.clear();     // 전송 후 비우기
      widget.controller.clear();
      _selectedTags.clear();
      _isSending = false;
    });
  }



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
              onTagChanged: (selectedTags) => setState(() => _selectedTags = selectedTags),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => setState(() => _selectedTags.remove(tag)),
            )).toList(),
          ),
        if (_pendingUploads.isNotEmpty)
          ImageUploadPreview(
            items: _pendingUploads,
            onRemove: (index) => setState(() => _pendingUploads.removeAt(index)),
            onReorder: (oldIndex, newIndex) => setState(() {
              if (oldIndex < newIndex) newIndex--;
              final item = _pendingUploads.removeAt(oldIndex);
              _pendingUploads.insert(newIndex, item);
            }),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showImageSourceSelector,
            ),
            Expanded(
              child: _dictionaryLoaded
                  ? CustomTypeAheadTextField(
                controller: widget.controller,
                dictionary: _dictionary,
                hintText: '메시지를 입력하세요',
                onSubmitted: (_) => _handleSubmit(),
              )
                  : const TextField(
                decoration: InputDecoration(
                  hintText: '로딩 중...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(width: 8),
            _isSending
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: const CircularProgressIndicator(strokeWidth: 2),
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
}
