// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/home_chat_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/todo_list_screen.dart';
import 'screens/done_list_screen.dart';
import 'providers/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main()
  async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    initializeDateFormatting('ko_KR', null); // 한국어 로케일 초기화

    runApp(
      ChangeNotifierProvider(
        create: (_) => ScheduleProvider(),
        child: const ChatDoApp(),
      ),
    );
  }

class ChatDoApp extends StatelessWidget {
  const ChatDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatDo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const MainTabController(),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;


  final List<Widget> _pages = [
    const HomeChatScreen(),
    const CalendarScreen(),
    const TodoListScreen(),
    const DoneListScreen(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
    BottomNavigationBarItem(icon: Icon(Icons.list), label: '할일'),
    BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: '한일'),
  ];

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
