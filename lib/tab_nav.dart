// lib/.../tab_nav.dart
import 'package:flutter/material.dart';
import 'chatdo/screens/home_chat_screen.dart';
import 'chatdo/screens/schedule_overview_screen.dart';
import 'chatdo/screens/menu_screen.dart';
import '../../game/core/game_controller.dart';
import 'chatdo/providers/audio_manager.dart';

// ⬇️ Godot 임베디드 화면 임포트
import 'chatdo/godot/godot_embed_screen.dart';

class TabNav extends StatefulWidget {
  const TabNav({super.key});

  @override
  State<TabNav> createState() => _TabNavState();
}

class _TabNavState extends State<TabNav> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late GameController _gameController;

  // “방” 탭 인덱스 (BottomNavigationBar 순서 기준)
  static const int roomTabIndex = 2;
  static const int moreTabIndex = 3;

  bool _launchingGodot = false; // 더블탭 디바운스용

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameController = GameController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      AudioManager.instance.stop(); // 🔇 백그라운드 가면 음악 멈춤
    }
  }

  Future<void> _launchGodotEmbedded() async {
    if (_launchingGodot) return;        // 중복 방지
    _launchingGodot = true;
    try {
      // 혹시 방 관련 BGM 깔려있으면 먼저 정지
      AudioManager.instance.stop();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GodotEmbedScreen()),
      );
    } finally {
      _launchingGodot = false;
    }
  }

  void _onItemTapped(int index) {
    // “방” 탭은 화면 전환 대신 액션만
    if (index == roomTabIndex) {
      _launchGodotEmbedded();
      return; // _selectedIndex 변경 안 함 → 현재 화면 유지
    }

    // 예전 로직에 “방에서 나갈 때 음악 정지”가 있었는데
    // 이제 방은 화면이 아니라 액션이니, 여기선 일반 탭 전환만 처리.
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeChatScreen(gameController: _gameController);
      case 1:
        return ScheduleOverviewScreen(gameController: _gameController);
      case moreTabIndex:
        return const MenuScreen();
      default:
      // 안전장치: 정의 안 된 인덱스면 기본 채팅으로
        return HomeChatScreen(gameController: _gameController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
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
            label: '방',        // ⬅️ 누르면 Godot 실행
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
