// tab_nav.dart
import 'package:flutter/material.dart';
import 'chatdo/screens/home_chat_screen.dart';
import 'chatdo/screens/room_screen.dart';
import 'chatdo/screens/schedule_overview_screen.dart';
import 'chatdo/screens/menu_screen.dart';
import '../../game/core/game_controller.dart';
import 'chatdo/providers/audio_manager.dart';
import '/game/components/flame/room_game.dart';

class TabNav extends StatefulWidget {
  const TabNav({super.key});

  @override
  State<TabNav> createState() => _TabNavState();
}

class _TabNavState extends State<TabNav> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late GameController _gameController;
  late RoomGame _roomGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameController = GameController();
    _roomGame = RoomGame(); // ✅ 여기서 한 번만 생성
    _pages = [
      HomeChatScreen(gameController: _gameController),
      ScheduleOverviewScreen(gameController: _gameController),
      RoomScreen(roomGame: _roomGame), // ✅ 재사용
      const MenuScreen(), // 추가: 메뉴 탭
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      AudioManager.instance.stop(); // 🔇 앱이 백그라운드로 가면 음악 멈춤
    }
  }


  void _onItemTapped(int index) {
    // 방 탭(2)에서 나갈 때 음악 정지
    if (_selectedIndex == 2 && index != 2) {
      AudioManager.instance.stop();
    }
    setState(() {
      _selectedIndex = index;

      // 방 탭에 진입할 때 resume 호출
      if (index == 2) {
        _roomGame.resumeGame();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            label: '방',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}