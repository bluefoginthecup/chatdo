import 'package:flutter/material.dart';
import 'chatdo/screens/home_chat_screen.dart';
import 'chatdo/screens/calendar_screen.dart';
import 'chatdo/screens/todo_list_screen.dart';
import 'chatdo/screens/done_list_screen.dart';
import 'chatdo/screens/room_screen.dart';

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeChatScreen(),
    CalendarScreen(),
    TodoListScreen(),
    DoneListScreen(),
    RoomScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
    BottomNavigationBarItem(icon: Icon(Icons.list), label: '할일'),
    BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: '한일'),
    BottomNavigationBarItem(icon: Icon(Icons.bedroom_baby), label: '방'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        items: _bottomItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
