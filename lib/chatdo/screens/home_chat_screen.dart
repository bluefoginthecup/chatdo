// home_chat_screen.dart (페이징 적용 + ListView.builder 버전)

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule_entry.dart';
import '../models/message.dart';
import '../services/sync_service.dart';
import '../widgets/chat_input_box.dart';
import '/game/core/game_controller.dart';
import '../screens/schedule_detail_screen.dart';
import '../models/enums.dart';
import '../widgets/chat_message_card.dart';
import '../data/firestore/repos/message_repo.dart';


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

  List<Map<String, dynamic>> _messageLog = [];

  String? _userId;
  late MessageRepo _messageRepo;

  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;
  late final StreamSubscription<ConnectivityResult> _subscription;

  bool _shouldRefocusOnResume = true;

  // 🔥 페이징 변수
  static const int _pageSize = 50;
  bool _isLoadingMore = false;
  int _loadedCount = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _userId = FirebaseAuth.instance.currentUser?.uid;
    _messageRepo = context.read<MessageRepo>();

    _initConnectivity();
    _scrollController.addListener(_onScroll);

    // 🔥 최신 50개만 불러오기 (중요)
    _loadInitialFromHive();

    SyncService.uploadAllIfConnected();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _subscription.cancel();
    _focusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 🔥 페이징: 최초 로드 (최신 N개)
  // ─────────────────────────────────────────────
  Future<void> _loadInitialFromHive() async {
    final box = Hive.box<Message>('messages');
    final keys = box.keys.toList();
    final len = keys.length;
    if (len == 0) return;

    final from = (len - _pageSize) < 0 ? 0 : (len - _pageSize);
    final to = len;

    final List<Map<String, dynamic>> slice = [];

    for (int i = from; i < to; i++) {
      final k = keys[i];
      final m = box.get(k);
      if (m is! Message) continue;

      final listUrls = (m.imageUrls ?? const <String>[]);
      final firstUrl = m.imageUrl ?? (listUrls.isNotEmpty ? listUrls.first : null);

      slice.add({
        'id': m.id,
        'content': m.text,
        'date': m.date.toString(),
        'type': m.type,
        if (firstUrl != null) 'imageUrl': firstUrl,
        'imageUrls': listUrls,
        'tags': m.tags ?? const <String>[],
        'timestamp': m.timestamp,
      });
    }

    slice.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

    setState(() {
      _messageLog = slice;
      _loadedCount = slice.length;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  // ─────────────────────────────────────────────
  // 🔥 페이징: 과거 더 불러오기
  // ─────────────────────────────────────────────
  Future<void> _loadMoreFromHive() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    try {
      final box = Hive.box<Message>('messages');
      final keys = box.keys.toList();
      final len = keys.length;

      if (_loadedCount >= len) return;

      final remain = len - _loadedCount;
      final take = remain >= _pageSize ? _pageSize : remain;
      final from = (len - _loadedCount - take);
      final to = (len - _loadedCount);

      final List<Map<String, dynamic>> more = [];

      for (int i = from; i < to; i++) {
        final k = keys[i];
        final m = box.get(k);
        if (m is! Message) continue;

        final listUrls = (m.imageUrls ?? const <String>[]);
        final firstUrl = m.imageUrl ?? (listUrls.isNotEmpty ? listUrls.first : null);

        more.add({
          'id': m.id,
          'content': m.text,
          'date': m.date.toString(),
          'type': m.type,
          if (firstUrl != null) 'imageUrl': firstUrl,
          'imageUrls': listUrls,
          'tags': m.tags ?? const <String>[],
          'timestamp': m.timestamp,
        });
      }

      more.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

      if (more.isNotEmpty) {
        setState(() {
          _messageLog = [...more, ..._messageLog];
          _loadedCount += more.length;
        });
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 150 && !_isLoadingMore) {
      _loadMoreFromHive();
    }
  }

  // ─────────────────────────────────────────────
  // 메시지 전송 (기존 그대로 유지)
  // ─────────────────────────────────────────────
  void _handleSendMessage(
      String text, Mode mode, DateTime date, List<String> tags,
      {List<String> localPaths = const []}) async {
    if (text.trim().isEmpty || _userId == null) return;

    final now = DateTime.now();
    final id = _messageRepo.newId(_userId!);

    final entry = ScheduleEntry(
      docId: id,
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      timestamp: now,
      tags: tags,
    );

    await _messageRepo.upsertEntry(_userId!, entry);

    final box = Hive.box<Message>('messages');
    await box.add(Message(
      id: id,
      text: entry.content,
      type: entry.type.name,
      date: DateFormat('yyyy-MM-dd').format(entry.date),
      timestamp: now.millisecondsSinceEpoch,
      imageUrl: entry.imageUrl,
      imageUrls: entry.imageUrls,
      tags: entry.tags,
      localImagePaths: localPaths,
      uploadState: localPaths.isEmpty ? 'done' : 'queued',
    ));

    setState(() {
      _messageLog.add({
        'id': id,
        'content': entry.content,
        'date': entry.date.toIso8601String(),
        'createdAt': now.millisecondsSinceEpoch,
        'role': 'me',
        if (entry.imageUrl != null) 'imageUrl': entry.imageUrl!,
        'imageUrls': entry.imageUrls ?? const <String>[],
        'tags': entry.tags,
        'localImagePaths': localPaths,
        'uploadState': localPaths.isEmpty ? 'done' : 'queued',
      });
      _loadedCount++;
    });

    _controller.clear();
    _scrollToBottom();

    if (localPaths.isNotEmpty) {
      SyncService.enqueueImageUpload(
        uid: _userId!,
        messageId: id,
        localPaths: localPaths,
      );
    }
  }

  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // 스크롤 화면 그리기 — ListView.builder 버전
  // ─────────────────────────────────────────────
  List<Widget> _buildMessageWidgets() {
    return []; // unused now
  }

  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatDo')),
      body: SafeArea(
        child: Column(
          children: [
            // 🔥 페이징되는 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messageLog.length,
                itemBuilder: (context, index) {
                  final msg = _messageLog[index];
                  final prev = index > 0 ? _messageLog[index - 1] : null;

                  final dateStr = (msg['date'] ?? '').toString();
                  final prevDateStr =
                  prev == null ? null : (prev['date'] ?? '').toString();
                  final showDateHeader = prevDateStr != dateStr;

                  return Column(
                    children: [
                      if (showDateHeader && DateTime.tryParse(dateStr) != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              DateFormat('yyyy년 M월 d일')
                                  .format(DateTime.parse(dateStr)),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ChatMessageCard(
                        msg: msg,
                        onOpenDetail: _openScheduleDetail,
                      ),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ChatInputBox(
                controller: _controller,
                focusNode: _focusNode,
                gameController: widget.gameController,
                onSubmitted: (text, mode, date, tags,
                    {localPaths = const []}) {
                  _handleSendMessage(text, mode, date, tags,
                      localPaths: localPaths);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScheduleDetail(Map<String, dynamic> msg) async {
    final typeName = (msg['type'] ?? 'todo').toString();

    final entry = ScheduleEntry(
      docId: msg['id'],
      content: msg['content'] ?? '',
      date: DateTime.tryParse(msg['date'] ?? '')?.toLocal() ?? DateTime.now(),
      type: typeName == 'done' ? ScheduleType.done : ScheduleType.todo,
      createdAt: DateTime.now(),
      timestamp: DateTime.now(),
      tags: (msg['tags'] ?? []).cast<String>(),
      imageUrl: msg['imageUrl'],
      imageUrls:
      msg['imageUrls'] != null ? List<String>.from(msg['imageUrls']) : [],
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(
          entry: entry,
          gameController: widget.gameController,
        ),
      ),
    );
  }

  void _initConnectivity() {
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged.map((event) {
      if (event is List<ConnectivityResult>) {
        return event.isNotEmpty ? event.first : ConnectivityResult.none;
      }
      return ConnectivityResult.none;
    });
    _subscription = _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        SyncService.uploadAllIfConnected();
      }
    });
  }
}
