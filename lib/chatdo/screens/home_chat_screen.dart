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
import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint용


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
  static const int _pageSize = 10;
  bool _isLoadingMore = false;
  int _loadedCount = 0;
  int _totalCount = 0; // 전체 개수 추적 (디버그 표시용)
  bool get _hasMoreLocal => _loadedCount < _totalCount;


  // 디버그 출력 도우미
    void _log(String msg) {
        if (kDebugMode) {
          debugPrint('[HomeChatPaging] $msg');
        }
      }


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

    _log('INIT: total=$len, pageSize=$_pageSize, range=[$from, $to)');

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
      _totalCount = len;
    });
    if (slice.isNotEmpty) {
            _log('INIT: loaded=${slice.length}, firstTs=${slice.first['timestamp']}, lastTs=${slice.last['timestamp']}');
        } else {
          _log('INIT: loaded=0');
        }

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

      if (_loadedCount >= len) {
                _log('LOAD_MORE: all loaded. loadedCount=$_loadedCount >= total=$len');
            return;
          }

      final remain = len - _loadedCount;
      final take = remain >= _pageSize ? _pageSize : remain;
      final from = (len - _loadedCount - take);
      final to = (len - _loadedCount);

    _log('LOAD_MORE: total=$len, loaded=$_loadedCount, remain=$remain, take=$take, range=[$from, $to)');
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
          _totalCount = len;
        });
    _log('LOAD_MORE: appended=${more.length}, newLoaded=$_loadedCount/${_totalCount}');
    } else {
        _log('LOAD_MORE: no more items found in range.');
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 150 && !_isLoadingMore) {
            _log('SCROLL: near top (pixels=${_scrollController.position.pixels}), trigger load more');
            _loadMoreFromHive();
        }

  }

  // 🔥 원격에서 과거 배치 1회 동기화 (Repo 호출)
    Future<int> _syncOlderFromRemoteOnce() async {
        final uid = _userId;
        if (uid == null) return 0;
        // 현재 화면에서 가장 오래된 ts 기준
        int oldestTs = DateTime.now().millisecondsSinceEpoch;
        if (_messageLog.isNotEmpty) {
          final ts = _messageLog.first['timestamp'];
          if (ts is int) oldestTs = ts;
        }
        final n = await _messageRepo.syncOlderToHive(
          uid: uid,
          olderThanTs: oldestTs,
          limit: _pageSize,
        );
        if (n > 0) {
          await _loadMoreFromHive(); // 갱신 반영
        }
        return n;
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
      _totalCount++; // 새 메시지도 전체 개수 +1 로 간주

    });
    _log('SEND: appended one. loadedCount=$_loadedCount / total=$_totalCount');


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
        appBar: AppBar(
                    title: const Text('ChatDo'),
                actions: [
              IconButton(
                tooltip: '원격 동기화',
                    icon: const Icon(Icons.sync),
                onPressed: () async {
                  final n = await _syncOlderFromRemoteOnce();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(n == 0 ? '원격에 더 없다' : '$n개 동기화')),
                  );
                },
              ),
            ],
          ),
      body: SafeArea(
        child: Column(
          children: [
            if (kDebugMode)
                          Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                        children: [
                          const Icon(Icons.bug_report, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                                  child: Text(
                                '[DEBUG] total: $_totalCount, loaded: $_loadedCount, pageSize: $_pageSize, isLoading: $_isLoadingMore',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                        ),
                      ],
                    ),
                  ),
            // 🔥 페이징되는 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

    // 맨 위 헤더 한 칸 추가 (로컬 더보기/원격 동기화 버튼)
                    itemCount: _messageLog.length + 1,

    itemBuilder: (context, index) {
    if (index == 0) {
                        return _buildHeaderBar();
                      }
                      final realIndex = index - 1;
                      final msg = _messageLog[realIndex];
                      final prev = realIndex > 0 ? _messageLog[realIndex - 1] : null;


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
    if (kDebugMode)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '[#${index + 1}/${_messageLog.length}] id=${msg['id'] ?? '-'} ts=${msg['timestamp'] ?? '-'}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
    }
    );
  }

    // ────────────────
    // 헤더(맨 위): 로컬 더보기 / 원격 동기화
    // ────────────────
    Widget _buildHeaderBar() {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_hasMoreLocal)
                OutlinedButton.icon(
                  icon: const Icon(Icons.expand_less),
                  label: const Text('과거 더보기(로컬)'),
                  onPressed: _loadMoreFromHive,
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('원격에서 가져오기'),
                  onPressed: () async {
                    final n = await _syncOlderFromRemoteOnce();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(n == 0 ? '원격에 더 없다' : '$n개 동기화')),
                    );
                  },
                ),
            ],
          ),
        );
      }
}
