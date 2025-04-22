// schedule_overview_screen.dart
import 'package:flutter/material.dart';
import '../../game/core/game_controller.dart';
import 'todo_list_screen.dart';
import 'done_list_screen.dart';
import 'calendar_screen.dart';

enum ViewMode { todo, done, calendar }

class ScheduleOverviewScreen extends StatefulWidget {
  final GameController gameController;
  const ScheduleOverviewScreen({super.key, required this.gameController});

  @override
  State<ScheduleOverviewScreen> createState() => _ScheduleOverviewScreenState();
}

class _ScheduleOverviewScreenState extends State<ScheduleOverviewScreen> {
  ViewMode _currentMode = ViewMode.todo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 일정 관리')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ViewMode.values.map((mode) {
              final label = {
                ViewMode.todo: '할일',
                ViewMode.done: '한일',
                ViewMode.calendar: '캘린더',
              }[mode]!;
              final isSelected = _currentMode == mode;
              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => setState(() => _currentMode = mode),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Divider(),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (_currentMode) {
                  case ViewMode.todo:
                    return TodoListScreen(gameController: widget.gameController);
                  case ViewMode.done:
                    return DoneListScreen(gameController: widget.gameController);
                  case ViewMode.calendar:
                    return CalendarScreen(gameController: widget.gameController);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
