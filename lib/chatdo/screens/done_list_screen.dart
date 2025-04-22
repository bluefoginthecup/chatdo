// done_list_screen.dart (공통 액션 적용)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart'; // ✅ 공통 액션 추가

class DoneListScreen extends StatefulWidget {
  final GameController gameController;
  const DoneListScreen({super.key, required this.gameController});

  @override
  State<DoneListScreen> createState() => _DoneListScreenState();
}

class _DoneListScreenState extends State<DoneListScreen> {
  DateTime _currentDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDonesForDate(_currentDate);
  }

  void _changeDateBy(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    _fetchDonesForDate(_currentDate);
  }

  List<Map<String, dynamic>> _donesForDate = [];

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
        .orderBy('timestamp')
        .get();

    final dones = snapshot.docs.map((doc) => {
      'id': doc.id,
      'content': doc['content'] as String,
    }).toList();

    setState(() {
      _donesForDate = dones;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 M월 d일').format(_currentDate);

    return Scaffold(
      appBar: AppBar(),
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
            child: _donesForDate.isEmpty
                ? const Center(child: Text('완료된 일이 없습니다.'))
                : ListView.builder(
              itemCount: _donesForDate.length,
              itemBuilder: (context, index) {
                final done = _donesForDate[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => markAsOtherType(
                      docId: done['id'],
                      currentMode: 'done',
                      gameController: widget.gameController,
                      currentDate: _currentDate,
                      onRefresh: () => _fetchDonesForDate(_currentDate),
                      context: context,
                    ),
                    child: const Icon(Icons.check_circle_outline),
                  ),
                  title: GestureDetector(
                    onDoubleTap: () => showEditOrDeleteDialog(
                      context: context,
                      docId: done['id'],
                      originalText: done['content'],
                      mode: 'done',
                      currentDate: _currentDate,
                      onRefresh: () => _fetchDonesForDate(_currentDate),
                    ),
                    child: Text(done['content'] ?? ''),
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
