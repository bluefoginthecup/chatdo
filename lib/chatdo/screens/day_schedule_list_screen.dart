import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../game/core/game_controller.dart';
import '../models/schedule_entry.dart';
import 'schedule_list_screen.dart';

class DayScheduleListsScreen extends StatefulWidget {
  final DateTime date;
  final GameController gameController;
  const DayScheduleListsScreen({
    super.key,
    required this.date,
    required this.gameController,
  });

  @override
  State<DayScheduleListsScreen> createState() => _DayScheduleListsScreenState();
}

class _DayScheduleListsScreenState extends State<DayScheduleListsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  DateTime _dKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this); // 0=할 일, 1=한 일
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _dKey(widget.date);
    final title = DateFormat('M월 d일 (E)', 'ko').format(d);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '할 일'), Tab(text: '한 일')],
        ),
      ),
      body: TabBarView(
        controller: _tab, // 좌우 스와이프
        children: [
          ScheduleListScreen(
            type: ScheduleType.todo,
            initialDate: d,
            gameController: widget.gameController,
          ),
          ScheduleListScreen(
            type: ScheduleType.done,
            initialDate: d,
            gameController: widget.gameController,
          ),
        ],
      ),
    );
  }
}
