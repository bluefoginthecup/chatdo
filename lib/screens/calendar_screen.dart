import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../widgets/chat_input_box.dart';
import '../utils/nlp_parser.dart';  // NlpParser 추가

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _calendarInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR'); // 한국어 날짜 포맷 초기화
  }

  void _showAddScheduleDialog(BuildContext context, DateTime selectedDate) {
    _calendarInputController.clear();  // 입력 초기화

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${DateFormat('yyyy년 MM월 dd일').format(selectedDate)} 일정 추가',
          ),
          content: ChatInputBox(
            controller: _calendarInputController,
            onSubmitted: (text) {
              final parsedResult = NlpParser.parse(text.trim());  // 파싱 처리
              if (parsedResult != null) {
                final newEntry = ScheduleEntry(
                  date: selectedDate,
                  type: parsedResult.type,  // "할일" / "한일" 구분
                  content: parsedResult.content,  // 내용
                );
                // 상태에 반영
                Provider.of<ScheduleProvider>(context, listen: false).addEntry(newEntry);
              }
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final allEntries = [...provider.todos, ...provider.dones];

    // 날짜별로 그룹핑
    Map<DateTime, List<ScheduleEntry>> groupedEvents = {};
    for (var entry in allEntries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      groupedEvents[key] = [...(groupedEvents[key] ?? []), entry];
    }

    List<ScheduleEntry> getEventsForDay(DateTime day) {
      final key = DateTime(day.year, day.month, day.day);
      return groupedEvents[key] ?? [];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar<ScheduleEntry>(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
            _selectedDay != null &&
                DateTime(day.year, day.month, day.day) ==
                    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            eventLoader: getEventsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('날짜를 선택하세요'))
                : ListView(
              children: getEventsForDay(_selectedDay!).map((entry) {
                final label = entry.type == ScheduleType.todo ? '할일' : '한일';
                final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
                return ListTile(
                  leading: Icon(
                    entry.type == ScheduleType.todo
                        ? Icons.check_box_outline_blank
                        : Icons.check_circle,
                    color: entry.type == ScheduleType.todo ? Colors.teal : Colors.grey,
                  ),
                  title: Text('$label: ${entry.content}'),
                  subtitle: Text(dateStr),
                );
              }).toList(),
            ),
          )
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        onPressed: () {
          _showAddScheduleDialog(context, _selectedDay!);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
