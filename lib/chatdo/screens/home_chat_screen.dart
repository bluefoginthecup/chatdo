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
import '../widgets/chat_message_card.dart';



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
      timestamp: DateTime.now(),
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
    final entry = ScheduleEntry(
      docId: msg['id'],
      content: msg['content'] ?? '',
      date: DateTime.tryParse(msg['date'] ?? '') ?? DateTime.now(),
      type: ScheduleType.todo,
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
                onSubmitted: _handleSendMessage,
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

      // ⚠️ 네가 ScheduleUseCase에서 쓰는 컬렉션 경로가 다르면 이 줄만 바꿔라.

      final ref = FirebaseFirestore.instance
          .collection('messages')
          .doc(uid)
          .collection('logs')
          .doc(id);

      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;


      final updatedText = (data['content'] ?? '').toString();
      final ts = data['date'];
      final updatedDate = ts is Timestamp ? ts.toDate() : DateTime.now();
      final updatedTags = (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      final updatedImageUrl = data['imageUrl'] as String?;
      final updatedImageUrls = (data['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

      final box = Hive.box<Message>('messages');

      // 키를 찾아서 그 슬롯만 교체(putAt 말고 put(키)로 안전하게)
      dynamic targetKey;
      for (final k in box.keys) {
        final m = box.get(k);
        if (m is Message && m.id == id) {
          targetKey = k;
          break;
        }
      }
      if (targetKey == null) return;

      final old = box.get(targetKey) as Message;

      // Message 모델에 copyWith가 있으면 그걸 쓰고,
      // 없으면 생성자로 새로 만들어도 됨. (여기서는 안전하게 새로 생성)
      final patched = Message(
        id: old.id,
        text: updatedText,
        type: old.type,                       // 기존 것 유지
        date: DateFormat('yyyy-MM-dd').format(updatedDate),
        timestamp: old.timestamp,             // 정렬 안 틀어지게 기존 유지
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
