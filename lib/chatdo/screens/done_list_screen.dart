import 'package:flutter/material.dart';
import '../../game/core/game_controller.dart';
import 'schedule_list_screen.dart';
import '../models/schedule_entry.dart'; // ScheduleType enum 들어있는 파일


class DoneListScreen extends StatelessWidget {
  final GameController gameController;
  const DoneListScreen({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    return ScheduleListScreen(
      type: ScheduleType.done,
      initialDate: DateTime.now(),
      gameController: gameController,
    );
  }
}
