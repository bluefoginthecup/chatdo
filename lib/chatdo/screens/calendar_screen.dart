// lib/chatdo/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/schedule_entry.dart';
import '../utils/schedule_actions.dart';
import '../../game/core/game_controller.dart';

class CalendarScreen extends StatefulWidget {
  final GameController gameController;
  const CalendarScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<ScheduleEntry>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .get();

    final events = <DateTime, List<ScheduleEntry>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      // Parse date field of mixed types
      final dateValue = data['date'];
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else {
        continue;
      }
      // Parse content
      final content = data['content'] as String? ?? '';
      // Parse timestamp
      final tsValue = data['timestamp'];
      DateTime createdAt;
      if (tsValue is String && tsValue.isNotEmpty) {
        createdAt = DateTime.parse(tsValue);
      } else if (tsValue is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(tsValue);
      } else if (tsValue is Timestamp) {
        createdAt = tsValue.toDate();
      } else {
        createdAt = date;
      }
      // Parse mode
      final modeRaw = data['mode'] as String? ?? 'todo';
      final type = modeRaw == 'done' ? ScheduleType.done : ScheduleType.todo;

      final entry = ScheduleEntry(
        content: content,
        date: date,
        createdAt: createdAt,
        type: type,
        docId: doc.id,
      );
      final dayKey = DateTime(date.year, date.month, date.day);
      events.putIfAbsent(dayKey, () => []).add(entry);
    }

    setState(() {
      _events = events;
    });
  }

  List<ScheduleEntry> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders<ScheduleEntry>(
              markerBuilder: (context, date, events) {
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
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _getEventsForDay(_selectedDate).length,
            itemBuilder: (context, index) {
              final entry = _getEventsForDay(_selectedDate)[index];
              final type = entry.type;
              final docId = entry.docId;
              if (type == null || docId == null) return const SizedBox.shrink();
              return ListTile(
                leading: GestureDetector(
                  onTap: () => markAsOtherType(
                    docId: docId,
                    currentMode: type.name,
                    gameController: widget.gameController,
                    currentDate: _selectedDate,
                    onRefresh: _loadAllEvents,
                    context: context,
                  ),
                  child: Icon(
                    type == ScheduleType.done ? Icons.check_circle_outline : Icons.circle_outlined,
                    color: type == ScheduleType.done ? Colors.grey : Colors.red,
                  ),
                ),
                title: GestureDetector(
                  onDoubleTap: () => showEditOrDeleteDialog(
                    context: context,
                    docId: docId,
                    originalText: entry.content,
                    mode: type.name,
                    currentDate: _selectedDate,
                    onRefresh: _loadAllEvents,
                  ),
                  child: Text(
                    entry.content,
                    style: TextStyle(color: type == ScheduleType.todo ? Colors.red : Colors.grey),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
    width: 6,
    height: 6,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}