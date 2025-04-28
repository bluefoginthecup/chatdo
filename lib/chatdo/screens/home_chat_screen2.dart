import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule_entry.dart';
import '../models/message.dart';
import '../providers/schedule_provider.dart';
import '../services/sync_service.dart';
import '../usecases/schedule_usecase.dart';
import '../widgets/chat_input_box.dart';
import '/game/core/game_controller.dart';

class HomeChatScreen extends StatefulWidget {
  final GameController gameController;
  const HomeChatScreen({super.key, required this.gameController});

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<ScheduleEntry> _messages = [];
  List<Map<String, String>> _messageLog = [];
  String? _userId;
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;
  late final StreamSubscription<ConnectivityResult> _subscription;
  bool _shouldRefocusOnResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _loadMessagesFromHive();
    SyncService.uploadAllIfConnected();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _subscription = _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        SyncService.uploadAllIfConnected();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldRefocusOnResume) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _loadMessagesFromHive() async {
    final box = Hive.box<Message>('messages');
    final loaded = box.values.toList();
    loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final newLog = loaded.map((m) => {
      'content': m.text,
      'date': m.date.toString(),
      if (m.imageUrl != null) 'imageUrl': m.imageUrl!,
    }).toList();
    setState(() {
      _messageLog = List<Map<String, String>>.from(newLog);
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  Future<void> _handleSendMessage(String text, Mode mode, DateTime date) async {

    if (text.trim().isEmpty || _userId == null) return;
    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(_userId).collection('logs').doc();
    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      docId: docRef.id,
    );
    await ScheduleUseCase.updateEntry(
      entry: entry,
      newType: entry.type,
      provider: context.read<ScheduleProvider>(),
      gameController: widget.gameController,
      firestore: FirebaseFirestore.instance,
      userId: _userId!,
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


    setState(() {
      _messages.add(entry);
      _messageLog.add({
        'content': entry.content,
        'date': entry.date.toIso8601String(),
      });
    });
    _controller.clear();
    _focusNode.unfocus();
    _shouldRefocusOnResume = true;
    _scrollToBottom();
  }

  // ... 생략된 import 및 클래스 선언 부분

  Future<void> _handleSendImage(File imageFile, Mode mode, DateTime date) async {
    if (_userId == null) return;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('chat_images').child(_userId!).child(fileName);
    print('📤 업로드 위치: ${ref.fullPath}');

    try {
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      print('✅ 업로드 완료: $downloadUrl');

      // 제목 + 내용 입력받기
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
      final docRef = FirebaseFirestore.instance.collection('messages').doc(_userId).collection('logs').doc();

      final entry = ScheduleEntry(
        content: title.isNotEmpty ? title : '[IMAGE]',
        date: date,
        type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
        createdAt: now,
        docId: docRef.id,
        imageUrl: downloadUrl,
        body: body.isNotEmpty ? body : null,
      );

      await ScheduleUseCase.updateEntry(
        entry: entry,
        newType: entry.type,
        provider: context.read<ScheduleProvider>(),
        gameController: widget.gameController,
        firestore: FirebaseFirestore.instance,
        userId: _userId!,
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

      if (mounted) {
        setState(() {
          _messages.add(entry);
          _messageLog.add({
            'content': entry.content,
            'date': entry.date.toIso8601String(),
            'imageUrl': downloadUrl,
          });
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Widget> _buildMessageWidgets() {
    List<Widget> widgets = [];
    String? lastDate;
    for (var msg in _messageLog) {
      final String content = msg['content'] ?? '';
      final String dateStr = msg['date'] ?? '';
      final parsedDate = DateTime.tryParse(dateStr);
      if (lastDate != dateStr) {
        lastDate = dateStr;
        if (parsedDate != null) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                DateFormat('yyyy년 M월 d일').format(parsedDate),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ));
        }
      }
      if (msg['imageUrl'] != null) {
        widgets.add(Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Image.network(msg['imageUrl']!, width: 200),
          ),
        ));
      } else {
        widgets.add(Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(content),
          ),
        ));
      }
    }
    return widgets;
  }

  void _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('ChatDo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '이미지 전송',
            onPressed: () async {
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (picked != null) {
                await _handleSendImage(File(picked.path), Mode.todo, DateTime.now());
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: '로그아웃', onPressed: _confirmAndLogout),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: _buildMessageWidgets(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ChatInputBox(
                gameController: widget.gameController,
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}