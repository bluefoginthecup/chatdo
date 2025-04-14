// home_chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_entry.dart';
import '../widgets/chat_input_box.dart';
import '../services/message_service.dart';


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

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _loadMessagesFromFirestore();
  }

  Future<void> _loadMessagesFromFirestore() async {
    if (_userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(_userId)
        .collection('logs')
        .orderBy('timestamp', descending: false)
        .get();

    final loadedMessages = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'content': data['content'] as String,
        'date': (data['date'] ?? '').toString(),
      };
    }).toList();

    setState(() {
      _messageLog = loadedMessages;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

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

    await _loadMessagesFromFirestore();
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
                onSubmitted: _handleSendMessage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
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
                    },
                    child: const Text("Hive 저장"),
                  ),
                  ElevatedButton(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
