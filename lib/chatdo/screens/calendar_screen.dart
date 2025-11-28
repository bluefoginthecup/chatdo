// lib/chatdo/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../../game/core/game_controller.dart';
import 'day_schedule_list_screen.dart'; // 새 래퍼(아래 코드)
import '../data/firestore/repos/message_repo.dart';
import 'package:provider/provider.dart';




class CalendarScreen extends StatefulWidget {
  final GameController gameController;
  const CalendarScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();


}
class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _dKey(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get _today => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  Map<DateTime, List<ScheduleEntry>> _allEntriesByDate = {};
  List<ScheduleEntry> _entriesForSelectedDate = [];
  bool _isLoading = true;
  late MessageRepo _messageRepo;
  String? _uid;


  @override
  void initState() {
    super.initState();
    _focusedDate = _today;
    _selectedDate = _today;
    _messageRepo = context.read<MessageRepo>();  // ✅ Repo 주입
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadAllEntriesForMonth(_focusedDate);
  }

  Future<void> _loadAllEntriesForMonth(DateTime monthDate) async {
    setState(() {
      _isLoading = true;              // ✅ 로딩 켜고
      _allEntriesByDate.clear();      // ✅ 이전 데이터 비우고
    });

    if (_uid == null) { setState(() => _isLoading = false); return; }
    try {
      final list = await _messageRepo.fetchMonth(_uid!, monthDate); // ✅ 경로 몰라도 됨

      final Map<DateTime, List<ScheduleEntry>> grouped = {};
      for (final e in list) {
        final d = e.date; // ScheduleEntry가 DateTime으로 파싱되어 있다고 가정
        final key = DateTime(d.year, d.month, d.day);
        (grouped[key] ??= <ScheduleEntry>[]).add(e);
      }
      setState(() {
        _allEntriesByDate = grouped;
        final key = _dKey(_selectedDate);
        _entriesForSelectedDate = _sortEntries(grouped[key] ?? const <ScheduleEntry>[]);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('calendar fetch error: $e');
      setState(() => _isLoading = false);
    }

  }

  List<ScheduleEntry> _getEventsForDay(DateTime day) {
    return _allEntriesByDate[_dKey(day)] ?? const <ScheduleEntry>[];
  }


  List<ScheduleEntry> _sortEntries(List<ScheduleEntry> entries) {
    final sorted = [...entries]; // 원본 건드리지 않게 복사
    sorted.sort((a, b) {
      // 1. 할일이 먼저
      if (a.type != b.type) {
        return a.type == ScheduleType.todo ? -1 : 1;
      }

      // 2. 태그 이름 기준
      final aTag = (a.tags.isNotEmpty ? a.tags.first : '').toLowerCase();
      final bTag = (b.tags.isNotEmpty ? b.tags.first : '').toLowerCase();
      final tagCompare = aTag.compareTo(bTag);
      if (tagCompare != 0) return tagCompare;

      // 3. 최신순 (timestamp 내림차순)
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => _loadAllEntriesForMonth(_focusedDate),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TableCalendar<ScheduleEntry>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDate = selected;
                    _focusedDate = focused;

                    final selectedEntries = _getEventsForDay(selected);
                    _entriesForSelectedDate = _sortEntries(selectedEntries);

                    // 디버깅용 로그
                    for (final e in selectedEntries) {
                      debugPrint('📌 ${e.type.name} / ${e.tags.isNotEmpty ? e.tags.first : '태그없음'} / ${e.content}');
                    }
                  });
                },

                onDayLongPressed: (selected, focused) {
                  // 날짜를 00:00으로 정규화해서 넘김
                  final d = DateTime(selected.year, selected.month, selected.day);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayScheduleListsScreen(
                        date: d,
                        gameController: widget.gameController,
                      ),
                    ),
                  );
                },

                onPageChanged: (focusedDay) {
                  _focusedDate = focusedDay;
                  _loadAllEntriesForMonth(focusedDay);
                },
                eventLoader: _getEventsForDay,
                calendarBuilders: CalendarBuilders<ScheduleEntry>(
                  markerBuilder: (ctx, date, events) {
                    final hasTodo = events.any((e) => e.type == ScheduleType.todo);
                    final hasDone = events.any((e) => e.type == ScheduleType.done);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasTodo) _dot(Colors.red),
                        if (hasDone) _dot(Colors.grey),
                      ],
                    );
                  },
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
              const Divider(),
              _entriesForSelectedDate.isEmpty
                  ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('해당 날짜에 일정이 없습니다.')),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _entriesForSelectedDate.length,
                itemBuilder: (context, i) {
                  final entry = _entriesForSelectedDate[i];
                  return ScheduleEntryTile(
                    entry: entry,
                    gameController: widget.gameController,
                    onRefresh: () => _loadAllEntriesForMonth(_focusedDate),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    width: 7,
    height: 7,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
