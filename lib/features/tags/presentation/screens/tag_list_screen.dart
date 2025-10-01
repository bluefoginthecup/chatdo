import 'package:flutter/material.dart';
import 'tag_log_screen.dart';
import 'tag_management_screen.dart';
import '/game/core/game_controller.dart';

class TagListScreen extends StatelessWidget {
  final GameController gameController;

  const TagListScreen({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 수정된 코드 👍
          TabBar(
            tabs: [
              Tab(text: '태그별 일정'),
              Tab(text: '태그 관리'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black87,
            indicator: BoxDecoration(
              color: Colors.teal.withOpacity(0.5), // 0.0 = 완전 투명, 1.0 = 불투명

              borderRadius: BorderRadius.circular(2),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                TagLogScreen(gameController: gameController),
                TagManagementScreen(gameController: gameController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
