// tab_nav.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatdo/screens/home_chat_screen.dart';
import 'chatdo/screens/room_screen.dart';
import 'chatdo/screens/schedule_overview_screen.dart';
import 'chatdo/screens/menu_screen.dart';
import '../../game/core/game_controller.dart';
import 'chatdo/providers/schedule_provider.dart';

class TabNav extends StatefulWidget {
  const TabNav({super.key});

  @override
  State<TabNav> createState() => _TabNavState();
}

class _TabNavState extends State<TabNav> {
  int _selectedIndex = 0;
  late GameController _gameController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _gameController = GameController();
    _pages = [
      HomeChatScreen(gameController: _gameController),
      ScheduleOverviewScreen(gameController: _gameController),
      RoomScreen(),
      const MenuScreen(), // 추가: 메뉴 탭
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider(),
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.view_agenda), label: '일정'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '방'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: '메뉴'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.teal,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}