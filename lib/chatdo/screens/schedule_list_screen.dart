import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../widgets/tags/tag_filter_bar.dart';
import '../../game/core/game_controller.dart';
import '../utils/friendly_date_utils.dart';
import '../models/enums.dart';


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

  // 날짜 스와이프 충돌 방지(가장자리에서만 날짜 넘김)
  final double _edgeWidth = 24;
  double _dragDistance = 0;
  double _dragStartX = 0;

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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(uid)
          .collection('logs')
          .where('mode', isEqualTo: widget.type.name)
          .where('date', isEqualTo: dateString)
          .orderBy('timestamp')
          .limit(200) // 과도한 로드 방지
          .get();

      final list = snapshot.docs
          .map((doc) => ScheduleEntry.fromFirestore(doc))
          .toList();

      setState(() {
        _entries = list;
        _isLoading = false;
      });
    } catch (e) {
      // 인덱스 미설정 등 오류 시 빈 목록 처리
      setState(() {
        _entries = [];
        _isLoading = false;
      });
    }
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

  // ===== 메뉴 기반 미루기/삭제 =====


  Future<bool> _confirmPostponeDialog() async {
  return await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
  title: const Text('미루기'),
  content: const Text('이 할 일을 내일로 미룰까요?'),
  actions: [
  TextButton(
  onPressed: () => Navigator.pop(ctx, false),
  child: const Text('아니오'),
  ),
  TextButton(
  onPressed: () => Navigator.pop(ctx, true),
  child: const Text('예'),
  ),
  ],
  ),
  ) ??
  false;
  }

  Future<void> _postponeEntryOneDay(ScheduleEntry entry) async {
    if (widget.type != ScheduleType.todo) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || entry.docId == null) return;

    // ✅ entry.date는 이미 DateTime이므로 parse 하지 말고 그대로 사용
    final base = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final next = base.add(const Duration(days: 1));

    // 저장은 'yyyy-MM-dd' 문자열로
    final currentYmd = DateFormat('yyyy-MM-dd').format(base);
    final nextYmd = DateFormat('yyyy-MM-dd').format(next);

    final ref = FirebaseFirestore.instance
        .collection('messages').doc(uid)
        .collection('logs').doc(entry.docId);

    // ✅ 최초 생성일(originDate) 없으면 한 번만 세팅
    await ref.set({
      'originDate': entry.originDate ?? currentYmd,
    }, SetOptions(merge: true));

    // ✅ 날짜 변경 + 카운트 증가 + 정렬 보정
    await ref.update({
      'date': nextYmd,
      'timestamp': FieldValue.serverTimestamp(),
      'postponedCount': FieldValue.increment(1),
    });

    await _loadEntries();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('내일($nextYmd)로 미뤘어요')),
    );
  }


  Widget _entryActionsButton(ScheduleEntry entry) {
  final isTodo = (widget.type == ScheduleType.todo);
  return PopupMenuButton<EntryAction>(
  icon: const Icon(Icons.more_vert),
  onSelected: (action) async {
  switch (action) {
  case EntryAction.postpone:
  if (!isTodo) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('완료된 일은 미룰 수 없어요.')),
  );
  return;
  }
  final ok = await _confirmPostponeDialog();
  if (ok) await _postponeEntryOneDay(entry);
  break;

  case EntryAction.delete:
  final ok = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
  title: const Text('삭제'),
  content: const Text('이 일정을 삭제할까요?'),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
  ],
  ),
  ) ??
  false;
  if (!ok) return;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance
      .collection('messages')
      .doc(uid)
      .collection('logs')
      .doc(entry.id)
      .delete();

  await _loadEntries();
  break;
  }
  },
  itemBuilder: (ctx) => <PopupMenuEntry<EntryAction>>[
  if (isTodo)
  const PopupMenuItem(
  value: EntryAction.postpone,
  child: Text('내일로 미루기'),
  ),
  const PopupMenuItem(
  value: EntryAction.delete,
  child: Text('삭제'),
  ),
  ],
  );
  }

  // ===== UI =====

  Widget _buildDateHeader() {
  final friendlyLabel = getFriendlyDateLabel(_currentDate);
  return Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  IconButton(
  icon: const Icon(Icons.arrow_left),
  onPressed: () => _changeDate(-1),
  ),
  Text(
  friendlyLabel,
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
  widget.type == ScheduleType.todo ? '할일이 없습니다.' : '완료된 일이 없습니다.',
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

  final tile = ScheduleEntryTile(
  entry: entry,
  gameController: widget.gameController,
  onRefresh: _loadEntries,
  );

  // ScheduleEntryTile에 trailing 슬롯이 없다고 가정 → Row로 우측 메뉴 붙임
  return Row(
  children: [
  Expanded(child: tile),
  _entryActionsButton(entry),
  const SizedBox(width: 8),
  ],
  );
  },
  ),
  );
  }

  @override
  Widget build(BuildContext context) {
  if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
  }

  Widget listContent = _buildContentArea();

  // 날짜 변경 시 하이라이트 효과
  listContent = AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  decoration: BoxDecoration(
  color: Colors.white.withOpacity(_highlight ? 0.8 : 1.0),
  borderRadius: BorderRadius.circular(12),
  ),
  child: listContent,
  );

  // 할일/한일 탭에서 가장자리 스와이프만 날짜 넘김 허용(아이템 스와이프와 충돌 방지)
  if (widget.type == ScheduleType.todo || widget.type == ScheduleType.done) {
  listContent = GestureDetector(
  behavior: HitTestBehavior.deferToChild, // 자식(리스트/타일) 제스처 우선
  onHorizontalDragStart: (details) {
  _dragStartX = details.globalPosition.dx;
  },
  onHorizontalDragUpdate: (details) {
  final width = MediaQuery.of(context).size.width;
  final inEdge = (_dragStartX <= _edgeWidth) || (_dragStartX >= width - _edgeWidth);
  if (!inEdge) return; // 중앙에서 시작하면 날짜 스와이프 비활성화
  _dragDistance += details.primaryDelta ?? 0;
  },
  onHorizontalDragEnd: (details) {
  final width = MediaQuery.of(context).size.width;
  final inEdge = (_dragStartX <= _edgeWidth) || (_dragStartX >= width - _edgeWidth);
  if (!inEdge) {
  _dragDistance = 0;
  return;
  }
  if (_dragDistance.abs() >= 40) {
  if (_dragDistance > 0) {
  _changeDate(-1);
  } else {
  _changeDate(1);
  }
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
