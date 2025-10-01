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
import 'chatdo/data/firestore/repos/text_dictionary_repo.dart';
import 'chatdo/features/text_dictionary/text_dictionary_provider.dart';

// progress 모듈
import '/game/progress/progress_provider.dart';
import '/game/progress/progress_service.dart';
import '/game/progress/progress_repo.dart';

// Hive
import 'package:hive_flutter/hive_flutter.dart';
import 'chatdo/models/message.dart';
import 'chatdo/stock/models/stock_item.dart'; // StockItemAdapter 등록용

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('🔥 Firebase initialized!');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Firebase init failed: $e');
  }

  // Intl (한국어 지역화)
  await initializeDateFormatting('ko_KR', null);

  // Hive
  await Hive.initFlutter();

  // Hive 어댑터 등록 (중복 등록 방지)
  if (!Hive.isAdapterRegistered(MessageAdapter().typeId)) {
    Hive.registerAdapter(MessageAdapter());
  }
  if (!Hive.isAdapterRegistered(StockItemAdapter().typeId)) {
    Hive.registerAdapter(StockItemAdapter());
  }

  // 필요한 박스 오픈 (커스텀 타입/큐 등)
  await Hive.openBox<Message>('messages');
  await Hive.openBox<Map>('syncQueue');

  runApp(
    MultiProvider(
      providers: [
        // 텍스트 사전 (Firestore 연동)
        ChangeNotifierProvider(
          create: (_) => TextDictionaryProvider()..load(),
        ),

        // 일정/스케줄
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),

        // 오디오 관리자
        Provider<AudioManager>(create: (_) => AudioManager()),

        // Firestore 경로 주입
        Provider<UserStorePaths>(
          create: (_) => FirestorePathsV1(FirebaseFirestore.instance),
        ),

        // Repos (경로 의존)
        ProxyProvider<UserStorePaths, RoutineRepo>(
          update: (_, paths, __) => RoutineRepo(paths),
        ),
        ProxyProvider<UserStorePaths, MessageRepo>(
          update: (_, paths, __) => MessageRepo(paths),
        ),
        ProxyProvider<UserStorePaths, TagRepo>(
          update: (_, paths, __) => TagRepo(paths),
        ),
        // (참고) TextDictionaryRepo는 TextDictionaryProvider 내부에서 사용/관리

        // Progress 모듈
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(
            ProgressService(ProgressRepo()),
          )..init(),
        ),
      ],
      child: const ChatDoApp(),
    ),
  );
}

class ChatDoApp extends StatelessWidget {
  const ChatDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'ChatDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // 로그인 여부에 따라 분기
      home: user == null ? const LoginScreen() : const TabNav(),
    );
  }
}
