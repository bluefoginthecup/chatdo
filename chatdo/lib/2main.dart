import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'tab_nav.dart';
import 'chatdo/screens/login_screen.dart';

// Providers & repos
import 'chatdo/providers/schedule_provider.dart';
import 'chatdo/providers/audio_manager.dart';
import 'chatdo/data/firestore/paths.dart';
import 'chatdo/data/firestore/repos/routine_repo.dart';
import 'chatdo/data/firestore/repos/message_repo.dart';
import 'chatdo/data/firestore/repos/tags_repo.dart';
import 'chatdo/features/text_dictionary/text_dictionary_provider.dart';

// progress
import '/game/progress/progress_provider.dart';
import '/game/progress/progress_service.dart';
import '/game/progress/progress_repo.dart';

// Hive
import 'package:hive_flutter/hive_flutter.dart';
import 'chatdo/models/message.dart';

// ✅ stock 모듈 (네임드 export 모음)
import 'chatdo/features/stock/stock.dart'; // stock_layer.dart, repos, sync 포함

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(MessageAdapter().typeId)) {
    Hive.registerAdapter(MessageAdapter());
  }
  await Hive.openBox<Message>('messages');
  await Hive.openBox<Map>('syncQueue');

  runApp(const ChatDoApp());
}

class ChatDoApp extends StatelessWidget {
  const ChatDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ “전역 MultiProvider”는 로그인 여부에 따라 분기하여 “로그인 되었을 때만” 올린다.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) return const LoginScreen();

          // 로그인 됨 → UID 의존 초기화 진행
          return _AppAfterLogin(uid: user.uid);
        },
      ),
    );
  }
}

/// 로그인 완료 후: UID 의존 초기화(StockLayer 등) → 최상단 MultiProvider로 앱 전체 감싸기
class _AppAfterLogin extends StatefulWidget {
  const _AppAfterLogin({required this.uid, super.key});
  final String uid;

  @override
  State<_AppAfterLogin> createState() => _AppAfterLoginState();
}

class _AppAfterLoginState extends State<_AppAfterLogin> {
  late Future<_BootResult> _boot;

  @override
  void initState() {
    super.initState();
    _boot = _initWithUid(widget.uid);
  }

  Future<_BootResult> _initWithUid(String uid) async {
    // ✅ StockLayer는 내부에서 Hive 박스/어댑터/원격 레포 준비 + SyncService 생성
    final stock = await StockLayer.init(uid: uid);
    // 자동 동기화 루프 시작(앱 로그인 시 1회)
    stock.sync.start();

    // 필요하면 다른 UID 의존 초기화도 여기서 수행

    return _BootResult(stockLayer: stock);
  }

  @override
  void dispose() {
    // 앱 나갈 때 동기화 타이머 정리(선택)
    try {
      _boot.then((r) => r.stockLayer.sync.stop());
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootResult>(
      future: _boot,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Init error: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final boot = snap.data!;

        // ✅ 여기서 “최상단” MultiProvider로 전체 앱을 감쌉니다.
        // TabNav, MenuScreen, ScheduleDetailScreen, StockListScreen 전부 아래에 있게 됨.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            Provider<AudioManager>(create: (_) => AudioManager()),

            // ------- Firestore 경로/레포 (UserStorePaths 먼저!) -------
            Provider<UserStorePaths>(
              create: (_) => FirestorePathsV1(FirebaseFirestore.instance),
            ),
            ProxyProvider<UserStorePaths, RoutineRepo>(
              update: (_, paths, __) => RoutineRepo(paths),
            ),
            ProxyProvider<UserStorePaths, MessageRepo>(
              update: (_, paths, __) => MessageRepo(paths),
            ),
            ProxyProvider<UserStorePaths, TagRepo>(
              update: (_, paths, __) => TagRepo(paths),
            ),

            // ------- 기타 전역 상태 -------
            ChangeNotifierProvider(
              create: (_) => ProgressProvider(ProgressService(ProgressRepo()))..init(),
            ),
            ChangeNotifierProvider(
              create: (_) => TextDictionaryProvider()..load(),
            ),

            // ------- ✅ stock: 하이브리드 레포 + 동기화 서비스 주입 -------
            Provider<StockRepo>.value(value: boot.stockLayer.repo),
            Provider<StockSyncService>.value(value: boot.stockLayer.sync),
          ],
          child: const TabNav(),
        );
      },
    );
  }
}

class _BootResult {
  _BootResult({required this.stockLayer});
  final StockLayer stockLayer;
}
