// done_list_screen.dart (공통 액션 적용)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../game/core/game_controller.dart';
import 'schedule_list_screen.dart';
import '../models/schedule_entry.dart';


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

    final dones = snapshot.docs.map((doc) =>
    {
      'id': doc.id,
      'content': doc['content'] as String,
    }).toList();

    setState(() {
      _donesForDate = dones;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScheduleListScreen(
      type: ScheduleType.done,
      initialDate: DateTime.now(),
      gameController: widget.gameController,

    );
  }
}