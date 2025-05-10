import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../widgets/tags/tag_filter_bar.dart';
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
  bool _slideFromRight = true;
  bool _highlight = false;


  String? _selectedTag;

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
    _slideFromRight = days > 0;
    _highlight = true;
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    await _loadEntries();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _highlight = false;
        });
      }
    });
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

  Widget _buildContentArea() {
    if (_entries.isEmpty) {
      return Center(
        child: Text(
          widget.type == ScheduleType.todo
              ? '할일이 없습니다.'
              : '완료된 일이 없습니다.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
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
    );
  }

  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget listContent = _buildContentArea();

    // 날짜가 바뀔 때마다 콘텐츠 전환 애니메이션 적용
    listContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_highlight ? 0.8 : 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: listContent,
    );



    // 할일/한일 탭이면 스와이프 감지 추가
    if (widget.type == ScheduleType.todo || widget.type == ScheduleType.done) {
      listContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          _dragDistance += details.primaryDelta ?? 0;
        },
        onHorizontalDragEnd: (details) {
          if (_dragDistance.abs() < 40) {
            _dragDistance = 0;
            return;
          }

          if (_dragDistance > 0) {
            _changeDate(-1);
          } else {
            _changeDate(1);
          }
          _dragDistance = 0;
        },
        child: listContent,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildDateHeader(),
        const SizedBox(height: 8),
        Expanded(child: listContent),
      ],
    );
  }


}
