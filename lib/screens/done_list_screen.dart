// done_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                '$formattedDate 한일 목록',
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
                  leading: const Icon(Icons.check_circle_outline),
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