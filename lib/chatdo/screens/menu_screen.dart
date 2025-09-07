import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/chatdo/features/text_dictionary/text_dictionary_screen.dart';
import 'hilohilo_game_view.dart';           // (HTML5 WebView)
import '../godot/godot_embed_screen.dart';          // ⬅️ 추가: iOS 임베디드 화면

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _isAutoPostponeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoPostponeEnabled = prefs.getBool('auto_postpone_enabled') ?? false;
    });
  }

  Future<void> _toggleAutoPostpone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_postpone_enabled', value);
    setState(() {
      _isAutoPostponeEnabled = value;
    });
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pop(); // 메뉴 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ⬆️ 여기 추가: iOS 임베디드 Godot 실행 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('iOS 임베디드 Godot 실행'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GodotEmbedScreen()),
                );
              },
            ),
          ),

          // 🔝 기존: 게임 테스트 (HTML5 WebView)
          ListTile(
            leading: const Icon(Icons.videogame_asset_outlined),
            title: const Text('게임 테스트 (Hilo Hilo)'),
            subtitle: const Text('Godot HTML5 → WebView'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HilohiloGameView()),
              );
            },
          ),

          // 📚 텍스트 사전 관리
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('텍스트 사전 관리'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TextDictionaryScreen()),
              );
            },
          ),

          const Divider(),

          // 🔁 자동 미루기 스위치
          SwitchListTile(
            title: const Text('자동 미루기'),
            subtitle: const Text('하루가 지나면 완료되지 않은 일정을 자동으로 다음날로 옮깁니다'),
            value: _isAutoPostponeEnabled,
            onChanged: _toggleAutoPostpone,
          ),

          const Divider(),

          // 🚪 로그아웃
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                onPressed: () => _confirmAndLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
