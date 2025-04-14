// done_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class DoneListScreen extends StatefulWidget {
  const DoneListScreen({super.key});

  @override
  State<DoneListScreen> createState() => _DoneListScreenState();
}

class _DoneListScreenState extends State<DoneListScreen> {
  DateTime _currentDate = DateTime.now();
  List<Map<String, dynamic>> _doneList = [];
  Set<int> _editingIndices = {};
  Map<int, TextEditingController> _editingControllers = {};

  final List<String> _encouragementMessages = [
    '💪 다시 시작할 수 있어요!',
    '📌 재도전, 멋집니다!',
    '🔄 아직 끝난 게 아니에요!',
    '🚀 다시 할일로 돌아왔어요!',
    '✨ 이번엔 꼭 마무리해봐요!',
    '📣 응원합니다! 파이팅!',
    '🔁 다시 달릴 시간이에요!',
    '💼 중요한 일이군요. 다시 도전!',
    '🔨 다시 잡은 기회, 멋져요!',
    '🧭 경로 재설정 완료!',
    "🛋️ 인생은 소파처럼 편하지 않다.",
    "🍜 삶이란 라면과 같다. 끓일 타이밍이 중요하다.",
    "🐢 느려도 괜찮아, 어차피 다 늦는다.",
    "🧹 엉망인 하루도 내 인생의 일부다.",
    "🐤 삶이란… 울다 웃다 치킨 시키는 일.",
    "☕ 인생은 커피다. 쓰지만 중독된다.",
    "🧠 삶에 정답은 없지만, 오답은 많다.",
    "🛑 가끔 멈춰야 한다. 너무 달리면 숨찬다.",
    "🎢 인생은 롤러코스터. 근데 안전바 없이 탄 느낌.",
    "🧘 괜찮아, 다들 대충 살고 있어.",
  ];

  @override
  void initState() {
    super.initState();
    _fetchDonesForDate(_currentDate);
  }

  Future<void> _fetchDonesForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('mode', isEqualTo: 'done')
        .where('date', isEqualTo: dateString)
        .get();

    final dones = snapshot.docs.map((doc) => {
      'id': doc.id,
      'content': doc['content'] as String,
    }).toList();

    setState(() {
      _doneList = dones;
      _editingIndices.clear();
      _editingControllers.clear();
    });
  }

  void _changeDateBy(int days) {
    final newDate = _currentDate.add(Duration(days: days));
    setState(() {
      _currentDate = newDate;
    });
    _fetchDonesForDate(newDate);
  }

  Future<void> _updateDone(String docId, String newText) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .update({'content': newText});

    _fetchDonesForDate(_currentDate);
  }

  Future<void> _deleteDone(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .delete();

    _fetchDonesForDate(_currentDate);
  }

  Future<void> _markAsTodo(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .update({'mode': 'todo'});

    final random = Random();
    final message = _encouragementMessages[random.nextInt(_encouragementMessages.length)];

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade200,
          content: Text(
            message,
            style: TextStyle(
              color: Colors.black, // 🖤 글자색: 블랙
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    _fetchDonesForDate(_currentDate);
  }

  void _enterEditMode(int index, String currentText) {
    setState(() {
      _editingIndices.add(index);
      _editingControllers[index] = TextEditingController(text: currentText);
    });
  }

  void _exitEditMode(int index) {
    setState(() {
      _editingIndices.remove(index);
      _editingControllers.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 M월 d일').format(_currentDate);

    return Scaffold(
      appBar: AppBar(title: const Text('한일 목록')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _changeDateBy(-1),
              ),
              Text(
                '$formattedDate',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _changeDateBy(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _doneList.isEmpty
                ? const Center(child: Text('한일이 없습니다.'))
                : ListView.builder(
              itemCount: _doneList.length,
              itemBuilder: (context, index) {
                final done = _doneList[index];
                final isEditing = _editingIndices.contains(index);
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _markAsTodo(done['id']),
                    child: const Icon(Icons.check_circle_outline),
                  ),
                  title: GestureDetector(
                    onDoubleTap: () => _enterEditMode(index, done['content']),
                    child: isEditing
                        ? TextField(
                      controller: _editingControllers[index],
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _updateDone(done['id'], value.trim());
                        }
                        _exitEditMode(index);
                      },
                    )
                        : Text(done['content']),
                  ),
                  trailing: isEditing
                      ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteDone(done['id']),
                  )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}