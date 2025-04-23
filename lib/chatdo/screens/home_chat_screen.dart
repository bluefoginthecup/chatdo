import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../widgets/chat_input_box.dart';
import '../models/message.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../services/sync_service.dart';
import '/game/core/game_controller.dart';
import '../usecases/schedule_usecase.dart';


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

    // 자동 포커스 (앱 처음 실행 시)
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


    }).toList();

    setState(() {
      _messageLog = newLog;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  Future<void> _handleSendMessage(String text, Mode mode, DateTime date) async {
    if (text.trim().isEmpty || _userId == null) return;

    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(_userId)
        .collection('logs')
        .doc();

    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      docId: docRef.id,
    );

    print('🚀 updateEntry 호출 직전: ${entry.content}, ${entry.type}');

    await ScheduleUseCase.updateEntry(
      entry: entry,
      newType: entry.type,
      provider: context.read<ScheduleProvider>(),
      gameController: widget.gameController,
      firestore: FirebaseFirestore.instance,
      userId: _userId!,
    );

    setState(() {
      _messages.add(entry); // 전체 메시지 리스트에 추가
      _messageLog.add({
        'content': entry.content,
        'date': entry.date.toIso8601String(), // String으로 확실하게 변환
      });
    });

    final box = await Hive.openBox('chat_messages');
    await box.put('messages', _messages.map((e) => e.toJson()).toList());

    _controller.clear();
    _focusNode.unfocus();
    _shouldRefocusOnResume = true;
    _scrollToBottom();
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
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  DateFormat('yyyy년 M월 d일').format(parsedDate), // ✅ 이제 안전
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }
      }

        widgets.add(
        Align(
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
        ),
      );
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
