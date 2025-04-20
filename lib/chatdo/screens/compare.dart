// tab_nav.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../game/core/game_controller.dart';
import '../screens/home_chat_screen.dart';
import '../screens/todo_list_screen.dart';
import '../screens/done_list_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/room_screen.dart';
import '../providers/schedule_provider.dart';

class TabNav extends StatefulWidget {
  const TabNav({super.key});

  @override
  State<TabNav> createState() => _TabNavState();
}

class _TabNavState extends State<TabNav> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GameController _gameController = GameController();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      HomeChatScreen(gameController: _gameController),
      CalendarScreen(),
      TodoListScreen(gameController: _gameController),
      DoneListScreen(),
      RoomScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: '할일'),
          BottomNavigationBarItem(icon: Icon(Icons.done), label: '한일'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '방'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}