// calendar_screen.dart (달력 UI 포함)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart';

class CalendarScreen extends StatefulWidget {
  final GameController gameController;
  const CalendarScreen({super.key, required this.gameController});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    _fetchCalendarEntries(_selectedDate!);
  }

  Future<void> _fetchCalendarEntries(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .where('date', isEqualTo: dateString)
        .orderBy('timestamp')
        .get();

    final list = snapshot.docs.map((doc) => {
      'id': doc.id,
      'content': doc['content'] as String,
      'mode': doc['mode'] as String,
    }).toList();

    setState(() {
      _entries = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDate,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDate = selected;
                _focusedDate = focused;
              });
              _fetchCalendarEntries(selected);
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const Divider(),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('해당 날짜에 일정이 없습니다.'))
                : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => markAsOtherType(
                      docId: entry['id'],
                      currentMode: entry['mode'],
                      gameController: widget.gameController,
                      currentDate: _selectedDate!,
                      onRefresh: () => _fetchCalendarEntries(_selectedDate!),
                      context: context,
                    ),
                    child: Icon(
                      entry['mode'] == 'done'
                          ? Icons.check_circle_outline
                          : Icons.circle_outlined,
                    ),
                  ),
                  title: GestureDetector(
                    onDoubleTap: () => showEditOrDeleteDialog(
                      context: context,
                      docId: entry['id'],
                      originalText: entry['content'],
                      mode: entry['mode'],
                      currentDate: _selectedDate!,
                      onRefresh: () => _fetchCalendarEntries(_selectedDate!),
                    ),
                    child: Text(entry['content'] ?? ''),
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
