import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 기능 화면들
import '/chatdo/features/text_dictionary/text_dictionary_screen.dart';
import 'hilohilo_game_view.dart';                 // (HTML5 WebView)
import '../godot/godot_embed_screen.dart';        // iOS 임베디드 화면
import 'profile_screen.dart';

// 재고 모듈
import 'package:hive_flutter/hive_flutter.dart';
import '../stock/models/stock_item.dart';
import '../stock/repo/hive_stock_repo.dart';
import '../stock/screens/stock_list_screen.dart';

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
      if (!mounted) return;
      Navigator.of(context).pop(); // 메뉴 닫기
    }
  }

  Future<void> _openStockModule(BuildContext context) async {
    // ✅ Hive 초기화 (이미 main.dart에서 했어도 안전)
    try {
      await Hive.initFlutter();
    } catch (_) {
      // 이미 초기화 된 경우 등은 무시
    }

    // ✅ 어댑터 등록 (중복등록 방지)
    if (!Hive.isAdapterRegistered(StockItemAdapter().typeId)) {
      Hive.registerAdapter(StockItemAdapter());
    }

    // ✅ 박스 오픈
    final itemsBox = await Hive.openBox<StockItem>('stock_items');
    final metaBox  = await Hive.openBox<List<String>>('stock_meta');

    final repo = HiveStockRepo(itemsBox, metaBox);

    // ✅ 기본 상위 폴더 보장
    final existing = await repo.watchFolders().first;
    if (existing.isEmpty) {
      for (final f in const ['goods', 'raw material', 'sub material']) {
        await repo.createFolder(f);
      }
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockListScreen(repo: repo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('프로필 / 계정'),
            subtitle: const Text('경험치 · 골드 확인'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),

          // iOS 임베디드 Godot 실행
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

          // 게임 테스트 (HTML5 WebView)
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

          // 텍스트 사전 관리
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

          // 재고관리
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('재고관리'),
            subtitle: const Text('완/반/원/부 간단 재고'),
            onTap: () => _openStockModule(context),
          ),

          const Divider(),

          // 자동 미루기 스위치
          SwitchListTile(
            title: const Text('자동 미루기'),
            subtitle: const Text('하루가 지나면 완료되지 않은 일정을 자동으로 다음날로 옮깁니다'),
            value: _isAutoPostponeEnabled,
            onChanged: _toggleAutoPostpone,
          ),

          const Divider(),

          // 로그아웃
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
