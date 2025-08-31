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
import '../services/sync_service.dart';
import '../widgets/chat_input_box.dart';
import '/game/core/game_controller.dart';
import '../screens/schedule_detail_screen.dart'; // ✅ 추가됨
import '../models/enums.dart'; // Mode, DateTag 가져오기
import '../widgets/chat_message_card.dart';
import '../data/firestore/repos/message_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';





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
  late MessageRepo _messageRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _messageRepo = context.read<MessageRepo>();

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
  Future<void> _loadMessagesFromHive() async {
    final box = Hive.box<Message>('messages');
    final loaded = box.values.toList();
    loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final newLog = loaded.map((m) {
      final listUrls = (m.imageUrls ?? const <String>[]);
      final firstUrl = m.imageUrl ?? (listUrls.isNotEmpty ? listUrls.first : null);
      return {
        'id': m.id,
        'content': m.text,
        'date': m.date.toString(),
        'type': m.type,
        if (firstUrl != null) 'imageUrl': firstUrl,      // ✅ 채팅 UI가 이 필드만 봐도 이미지 뜸
        'imageUrls': listUrls,                            // (유지)
        'tags': m.tags ?? const <String>[],              // (널 안전)
      };
    }).toList();


    setState(() {
      _messageLog = List<Map<String, dynamic>>.from(newLog);

    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }
  void _handleSendMessage(
      String text, Mode mode, DateTime date, List<String> tags,{
  List<String> localPaths = const [],

      }) async {

    if (text.trim().isEmpty || _userId == null) return;
    final now = DateTime.now();
    final id = _messageRepo.newId(_userId!); // ✅ repo에서 ID 발급

    final entry = ScheduleEntry(
      docId: id,
      content: text,
      date: date,                                  // 사용자가 고른 로컬 날짜
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
      createdAt: now,
      timestamp: now,                              // 화면 정렬 기준
      tags: tags,
    );
    // ✅ Firestore 저장 (있으면 업데이트, 없으면 생성)
    await _messageRepo.upsertEntry(_userId!, entry);
    // ✅ 로컬(Hive)에도 반영
    final box = await Hive.openBox<Message>('messages');
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
      uploadState: localPaths.isEmpty ? 'done' : 'queued', // 🔹 상태
    ));

    // ✅ 화면 목록 갱신
    setState(() {
      _messages.add(entry);
      _messageLog.add({
        'id': id,
        'content': entry.content,
        'date': entry.date.toIso8601String(),
        if (entry.imageUrl != null) 'imageUrl': entry.imageUrl!,
        'imageUrls': entry.imageUrls ?? const <String>[],
        'tags': entry.tags,
        'localImagePaths': localPaths,
        'uploadState': localPaths.isEmpty ? 'done' : 'queued',
      });
    });
    _controller.clear();
    _focusNode.unfocus();
    _shouldRefocusOnResume = true;
    _scrollToBottom();
    // _handleSendMessage 끝부분에 추가
    if (localPaths.isNotEmpty) {
      SyncService.enqueueImageUpload(
        uid: _userId!,
        messageId: id,
        localPaths: localPaths,
      );
    }

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

      final hasText = (content.trim().isNotEmpty);
      Widget messageContent = hasText
          ? Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(content),
      )
          : const SizedBox.shrink();


      widgets.add(ChatMessageCard(
        msg: msg,
        onOpenDetail: _openScheduleDetail,
      ));
    }

    return widgets;
  }

  Future<void> _openScheduleDetail(Map<String, dynamic> msg) async {
    final typeName = (msg['type'] ?? 'todo').toString();
    final entry = ScheduleEntry(
      docId: msg['id'],
      content: msg['content'] ?? '',
      date: DateTime.tryParse(msg['date'] ?? '')?.toLocal() ?? DateTime.now(),
      type: typeName == 'done' ? ScheduleType.done : ScheduleType.todo, // ✅
      createdAt: DateTime.now(),
      tags: msg['tags'] != null
          ? (msg['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      timestamp: DateTime.now(),
      imageUrl: msg['imageUrl'],
      imageUrls: msg['imageUrls'] != null
          ? List<String>.from(msg['imageUrls'])
          : [],
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
    final String scheduleId = (msg['id'] ?? '').toString();
    if (scheduleId.isNotEmpty) {
      await _syncOneFromRemote(scheduleId);
      await _loadMessagesFromHive(); // 화면 다시 로드
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('ChatDo'),

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
                onSubmitted: (text, mode, date, tags, {localPaths = const []}) {
                  _handleSendMessage(text, mode, date, tags, localPaths: localPaths);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _syncOneFromRemote(String id) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

   final snap = await context.read<MessageRepo>().getDoc(uid, id);


      final data = snap.data() as Map<String, dynamic>;

      // 2) 원격 데이터 파싱
      final updatedText = (data['text'] ?? data['content'] ?? '').toString();

      // ✅ 날짜는 로컬로
      final ts = data['date'];
      final updatedDate = ts is Timestamp
          ? ts.toDate().toLocal()
          : DateTime.tryParse(ts?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final updatedTags = (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      final updatedImageUrl = data['imageUrl'] as String?;
      final updatedImageUrls = (data['imageUrls'] as List?)?.map((e) => e.toString()).toList()
          ?? const <String>[];
      final remoteTypeStr = (data['type'] ?? data['mode'] ?? '').toString();


      final box = Hive.box<Message>('messages');
      dynamic targetKey;
      Message? old;
      for (final k in box.keys) {
        final m = box.get(k);
        if (m is Message && m.id == id) { targetKey = k; old = m; break; }
      }
      if (targetKey == null || old == null) return;

      final typeForHive = remoteTypeStr.isNotEmpty ? remoteTypeStr
          : (old.type.isNotEmpty ? old.type : 'todo');

      // 5) 패치해서 저장
      final patched = Message(
        id: old.id,
        text: updatedText,
        type: typeForHive, // ← 여기서 old를 이미 확보했으니 오류 없음
        date: DateFormat('yyyy-MM-dd').format(updatedDate),
        timestamp: old.timestamp, // 정렬 유지
        imageUrl: updatedImageUrl,
        imageUrls: updatedImageUrls.isEmpty ? old.imageUrls : updatedImageUrls,
        tags: updatedTags.isEmpty ? old.tags : updatedTags,
      );

      await box.put(targetKey, patched);
    } catch (e) {
      debugPrint('syncOneFromRemote error: $e');
    }
  }

}
