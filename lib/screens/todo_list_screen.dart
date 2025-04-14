// todo_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _currentDate = DateTime.now();
  List<Map<String, dynamic>> _todoList = [];
  Set<int> _editingIndices = {};
  Map<int, TextEditingController> _editingControllers = {};

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
  void initState() {
    super.initState();
    _fetchTodosForDate(_currentDate);
  }

  Future<void> _fetchTodosForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('mode', isEqualTo: 'todo')
        .where('date', isEqualTo: dateString)
        .get();

    final todos = snapshot.docs.map((doc) => {
      'id': doc.id,
      'content': doc['content'] as String,
    }).toList();

    setState(() {
      _todoList = todos;
      _editingIndices.clear();
      _editingControllers.clear();
    });
  }

  void _changeDateBy(int days) {
    final newDate = _currentDate.add(Duration(days: days));
    setState(() {
      _currentDate = newDate;
    });
    _fetchTodosForDate(newDate);
  }

  Future<void> _markAsDone(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .update({'mode': 'done'});

    final random = Random();
    final message = _celebrationMessages[random.nextInt(_celebrationMessages.length)];

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
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

    _fetchTodosForDate(_currentDate);
  }

  Future<void> _updateTodo(String docId, String newText) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .update({'content': newText});

    _fetchTodosForDate(_currentDate);
  }

  Future<void> _deleteTodo(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .doc(docId)
        .delete();

    _fetchTodosForDate(_currentDate);
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
            child: _todoList.isEmpty
                ? const Center(child: Text('할일이 없습니다.'))
                : ListView.builder(
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                final todo = _todoList[index];
                final isEditing = _editingIndices.contains(index);
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _markAsDone(todo['id']),
                    child: const Icon(Icons.circle_outlined),
                  ),
                  title: GestureDetector(
                    onDoubleTap: () => _enterEditMode(index, todo['content']),
                    child: isEditing
                        ? TextField(
                      controller: _editingControllers[index],
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _updateTodo(todo['id'], value.trim());
                        }
                        _exitEditMode(index);
                      },
                    )
                        : Text(todo['content']),
                  ),
                  trailing: isEditing
                      ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTodo(todo['id']),
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
