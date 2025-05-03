import 'package:flutter/material.dart';
import 'todo_list_screen.dart';
import 'done_list_screen.dart';
import 'calendar_screen.dart';
import 'routine_list_screen.dart'; // 루틴 화면 추가
import '/game/core/game_controller.dart';
import 'tag_list_screen.dart';

class ScheduleOverviewScreen extends StatelessWidget {
  final GameController gameController;

  const ScheduleOverviewScreen({Key? key, required this.gameController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // 할일, 한일, 캘린더, 루틴
      child: Scaffold(
        appBar: AppBar(
          title: const Text('일정 관리'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '할일'),
              Tab(text: '한일'),
              Tab(text: '캘린더'),
              Tab(text: '루틴'),
              Tab(text: '태그'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TodoListScreen(gameController: gameController),
            DoneListScreen(gameController: gameController),
            CalendarScreen(gameController: gameController),
            RoutineListScreen(),
            TagListScreen(gameController: gameController),
          ],
        ),
      ),
    );
  }
}
