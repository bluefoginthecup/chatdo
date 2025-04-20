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
import '../services/message_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../services/sync_service.dart';

class HomeChatScreen extends StatefulWidget {
  const HomeChatScreen({super.key});

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
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
      'date': m.date,
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
    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
    );
    Provider.of<ScheduleProvider>(context, listen: false).addEntry(entry);
    _controller.clear();

    _focusNode.unfocus(); // 메시지 전송 시 포커스 해제
    _shouldRefocusOnResume = true; // 다시 앱 열면 포커스 재개

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(_userId)
        .collection('logs')
        .add({
      'content': text,
      'mode': mode.name,
      'date': date.toIso8601String().substring(0, 10),
      'timestamp': now.toIso8601String(),
    });

    await _loadMessagesFromHive();
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

      if (lastDate != dateStr) {
        lastDate = dateStr;
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  DateFormat('yyyy년 M월 d일').format(parsed),
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
