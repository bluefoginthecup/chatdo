// lib/chatdo/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_entry.dart';
import '../widgets/schedule_entry_tile.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart';

class CalendarScreen extends StatefulWidget {
  final GameController gameController;
  const CalendarScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<ScheduleEntry>> _allEntriesByDate = {};
  List<ScheduleEntry> _entriesForSelectedDate = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllEntriesForMonth(_focusedDate);
  }

  Future<void> _loadAllEntriesForMonth(DateTime monthDate) async {
    setState(() {
      _isLoading = true;
      _allEntriesByDate.clear();
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('timestamp', isGreaterThanOrEqualTo: firstDay.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: lastDay.toIso8601String())
        .get();

    final Map<DateTime, List<ScheduleEntry>> grouped = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = DateTime.parse(data['date']);
      final ts = data['timestamp'];
      DateTime createdAt;
      if (ts is String) createdAt = DateTime.parse(ts);
      else if (ts is int) createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
      else if (ts is Timestamp) createdAt = ts.toDate();
      else createdAt = date;

      final entry = ScheduleEntry(
        content: data['content']?.toString() ?? '',
        date: date,
        createdAt: createdAt,
        type: (data['mode'] ?? 'todo') == 'done' ? ScheduleType.done : ScheduleType.todo,
        docId: doc.id,
      );
      final key = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    setState(() {
      _allEntriesByDate = grouped;
      _entriesForSelectedDate = grouped[_selectedDate] ?? [];
      _isLoading = false;
    });
  }

  List<ScheduleEntry> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _allEntriesByDate[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
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
                    _entriesForSelectedDate = _getEventsForDay(selected);
                  });
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
