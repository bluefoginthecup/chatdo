import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore는 추후 sync에 사용 가능
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

class _HomeChatScreenState extends State<HomeChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messageLog = [];
  String? _userId;
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;
  late final StreamSubscription<ConnectivityResult> _subscription;
  final FocusNode _focusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _loadMessagesFromHive(); // ✅ Hive 메시지 불러오기
    SyncService.uploadAllIfConnected(); // 앱 실행 시 초기 1회 동기화

    // ✅ 네트워크 변화 감지해서 자동 업로드
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _subscription = _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        SyncService.uploadAllIfConnected(); // 인터넷 연결되면 동기화
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }


  // ✅ Hive에서 메시지를 불러오는 함수
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

  // 🔁 아직 Firestore도 쓰고 있다면 (향후 syncQueue로 옮기기 예정)
  Future<void> _handleSendMessage(String text, Mode mode, DateTime date) async {
    if (text.trim().isEmpty || _userId == null) return;

    final entry = ScheduleEntry(
      content: text,
      date: date,
      type: mode == Mode.todo ? ScheduleType.todo : ScheduleType.done,
    );
    Provider.of<ScheduleProvider>(context, listen: false).addEntry(entry);
    _controller.clear();

    final now = DateTime.now();

    // ✅ 향후에는 Hive + syncQueue로 대체할 수 있음
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

    await _loadMessagesFromHive(); // ✅ Hive 기준으로 다시 로딩
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                // mainAxisAlignment는 Expanded로 감싸서 공간을 균등하게 차지하므로 생략해도 무방합니다.
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final dateStr = now.toIso8601String().substring(0, 10);
                        await MessageService.addMessage(
                          'Hive 저장 테스트 메시지',
                          '할일',
                          dateStr,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Hive에 메시지 저장됨')),
                        );
                        await _loadMessagesFromHive(); // 저장 후 새로 불러오기
                      },
                      child: const Text("Hive 저장"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final list = MessageService.getAllMessages();
                        for (final m in list) {
                          debugPrint('${m.id} | ${m.text} | ${m.date}');
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('📤 ${list.length}개 메시지 콘솔 출력')),
                        );
                      },
                      child: const Text("Hive 조회"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final syncBox = Hive.box<Map>('syncQueue');
                        await syncBox.add({
                          "type": "add_message",
                          "data": {
                            "id": "1234",
                            "text": "테스트 메시지",
                            "type": "할일",
                            "date": "2025-04-14",
                            "timestamp": DateTime.now().millisecondsSinceEpoch,
                          },
                          "timestamp": DateTime.now().millisecondsSinceEpoch,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ syncQueue에 메시지 추가됨')),
                        );
                      },
                      child: const Text("SyncQueue 테스트"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
