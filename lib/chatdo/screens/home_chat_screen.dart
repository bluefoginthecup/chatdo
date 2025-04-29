// home_chat_screen.dart (최종 통합 수정본)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule_entry.dart';
import '../models/message.dart';
import '../providers/schedule_provider.dart';
import '../services/sync_service.dart';
import '../usecases/schedule_usecase.dart';
import '../widgets/chat_input_box.dart';
import '/game/core/game_controller.dart';
import '../screens/schedule_detail_screen.dart'; // ✅ 추가됨
import '../models/enums.dart'; // Mode, DateTag 가져오기


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
  List<Map<String, dynamic>> _messageLog = [];

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
      'id': m.id,
      'content': m.text,
      'date': m.date.toString(),
      if (m.imageUrl != null) 'imageUrl': m.imageUrl!,
      'tags': m.tags,
    }).toList();
    setState(() {
      _messageLog = List<Map<String, dynamic>>.from(newLog);

    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }
  void _handleSendMessage(String text, Mode mode, DateTime date, List<String> tags)
 async {

    if (text.trim().isEmpty || _userId == null) return;
    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance.collection('messages').doc(_userId).collection('logs').doc();
    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      docId: docRef.id,
      tags: tags,
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
        'id': entry.docId ?? '',
        'content': entry.content,
        'date': entry.date.toIso8601String(),
        if (entry.imageUrl != null) 'imageUrl': entry.imageUrl!,
        'tags': entry.tags,
      });
    });
    _controller.clear();
    _focusNode.unfocus();
    _shouldRefocusOnResume = true;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      final imageUrl = msg['imageUrl'];

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

      Widget messageContent;
      if (imageUrl != null) {
        messageContent = Image.network(imageUrl, width: 200);
      } else {
        messageContent = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(content),
        );
      }

      widgets.add(
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onDoubleTap: () {
              _openScheduleDetail(msg);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  messageContent,
                  IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: () {
                      _openScheduleDetail(msg);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _openScheduleDetail(Map<String, dynamic> msg) {
    final entry = ScheduleEntry(
      docId: msg['id'],
      content: msg['content'] ?? '',
      date: DateTime.tryParse(msg['date'] ?? '') ?? DateTime.now(),
      type: ScheduleType.todo,
      createdAt: DateTime.now(),
      tags: msg['tags'] != null
          ? (msg['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],

    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(
          entry: entry,
          gameController: widget.gameController,
        ),
      ),
    );
  }

  void _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
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
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _confirmAndLogout,
          ),
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
