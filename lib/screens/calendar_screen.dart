// calendar_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _messagesByDate = {};

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(uid)
        .collection('logs')
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] ?? '').toString();
      if (date.isEmpty) continue;
      grouped.putIfAbsent(date, () => []).add({
        'content': data['content'] ?? '',
        'mode': data['mode'] ?? '',
      });
    }

    setState(() {
      _messagesByDate = grouped;
    });
  }

  List<Map<String, dynamic>> _getMessagesForDay(DateTime day) {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    return _messagesByDate[dateString] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedMessages = _getMessagesForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: selectedMessages.isEmpty
                ? const Center(child: Text('기록이 없습니다.'))
                : ListView.builder(
              itemCount: selectedMessages.length,
              itemBuilder: (context, index) {
                final message = selectedMessages[index];
                final isTodo = message['mode'] == 'todo';
                return ListTile(
                  leading: Icon(
                    isTodo ? Icons.circle_outlined : Icons.check_circle_outline,
                    color: isTodo ? Colors.red : Colors.grey,
                  ),
                  title: Text(
                    message['content'],
                    style: TextStyle(
                      color: isTodo ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
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