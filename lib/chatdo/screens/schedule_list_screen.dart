// lib/chatdo/screens/schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../../game/core/game_controller.dart';

class ScheduleListScreen extends StatefulWidget {
  final ScheduleType type;
  final DateTime initialDate;
  final GameController gameController;

  const ScheduleListScreen({
    Key? key,
    required this.type,
    required this.initialDate,
    required this.gameController,
  }) : super(key: key);

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  late DateTime _currentDate;
  List<ScheduleEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
      return;
    }
    final dateString = DateFormat('yyyy-MM-dd').format(_currentDate);
    late QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(uid)
          .collection('logs')
          .where('mode', isEqualTo: widget.type.name)
          .where('date', isEqualTo: dateString)
          .orderBy('timestamp')
          .get();
    } catch (_) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
      return;
    }
    final list = snapshot.docs.map(
            (doc) => ScheduleEntry.fromFirestore(doc)).toList();
    setState(() {
      _entries = list;
      _isLoading = false;
    });
  }

  Future<void> _changeDate(int days) async {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    await _loadEntries();
  }

  Widget _buildDateHeader() {
    final formatted = DateFormat('yyyy년 M월 d일').format(_currentDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () => _changeDate(-1),
        ),
        Text(
          formatted,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: () => _changeDate(1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 16),
          _buildDateHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                widget.type == ScheduleType.todo
                    ? '할일이 없습니다.'
                    : '완료된 일이 없습니다.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildDateHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEntries,
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ScheduleEntryTile(
                  entry: entry,
                  gameController: widget.gameController,
                  onRefresh: _loadEntries,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
