// todo_list_screen.dart (자동 새로고침 + 공통 액션 적용)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart'; // ✅ 공통 액션 가져오기

class TodoListScreen extends StatefulWidget {
  final GameController gameController;
  const TodoListScreen({super.key, required this.gameController});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _currentDate = DateTime.now();
  final List<String> _celebrationMessages = [
    '🎉 할일 완료! 수고하셨습니다!',
    '👏 잘했어요! 하나 끝!',
    '✅ 똑똑하게 처리했네요!',
    '🌟 완벽해요! 계속 이어가요!',
    '💪 굿잡! 다음도 화이팅!',
    '🙌 멋지게 해냈어요!',
    '🥳 좋아요! 하나 더 도전?',
    '🧠 똑똑한 선택이었어요!',
    '🕊️ 마음이 한결 가볍겠네요!',
    '🔥 완전 집중모드였어요!'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTodosForDate(_currentDate);
  }

  void _changeDateBy(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    _fetchTodosForDate(_currentDate);
  }

  List<Map<String, dynamic>> _todosForDate = [];
  Future<void> _fetchTodosForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    QuerySnapshot<Map<String, dynamic>>? snapshot;

    try {
      snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(uid)
          .collection('logs')
          .where('mode', isEqualTo: 'todo')
          .where('date', isEqualTo: dateString)
          .orderBy('timestamp')
          .get();
    } catch (e) {
      print('🔥 쿼리 에러: $e');
      return;
    }

    print('📥 받아온 문서 수: ${snapshot.docs.length}');
    print('📥 각 mode: ${snapshot.docs.map((doc) => doc['mode']).toList()}');


    final todos = snapshot.docs.map((doc) => {
      'id': doc.id,
      'content': doc['content'] as String,
    }).toList();

    setState(() {
      _todosForDate = todos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 M월 d일').format(_currentDate);

    return Scaffold(
      appBar: AppBar(title: const Text('할일 목록')),
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
                formattedDate,
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
            child: _todosForDate.isEmpty
                ? const Center(child: Text('할일이 없습니다.'))
                : ListView.builder(
              itemCount: _todosForDate.length,
              itemBuilder: (context, index) {
                final todo = _todosForDate[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => markAsOtherType(
                      docId: todo['id'],
                      currentMode: 'todo',
                      gameController: widget.gameController,
                      currentDate: _currentDate,
                      onRefresh: () => _fetchTodosForDate(_currentDate),
                      context: context,
                    ),
                    child: const Icon(Icons.circle_outlined),
                  ),
                  title: GestureDetector(
                    onDoubleTap: () => showEditOrDeleteDialog(
                      context: context,
                      docId: todo['id'],
                      originalText: todo['content'],
                      mode: 'todo',
                      currentDate: _currentDate,
                      onRefresh: () => _fetchTodosForDate(_currentDate),
                    ),
                    child: Text(todo['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
