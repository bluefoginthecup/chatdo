import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'tab_nav.dart';
import 'chatdo/screens/login_screen.dart';
import 'chatdo/providers/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatdo/models/message.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chatdo/providers/audio_manager.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatdo/data/firestore/paths.dart';
import 'chatdo/data/firestore/repos/routine_repo.dart';
import 'chatdo/data/firestore/repos/message_repo.dart';
import 'chatdo/data/firestore/repos/tags_repo.dart';
import 'chatdo/data/firestore/repos/text_dictionary_repo.dart';
import 'package:provider/provider.dart';
import 'chatdo/features/text_dictionary/text_dictionary_provider.dart';
// progress 모듈 (캔버스에 올려둔 경로 기준)
import '/game/progress/progress_provider.dart';
import '/game/progress/progress_service.dart';
import '/game/progress/progress_repo.dart';








void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialized!');
  } catch (e) {
    print('❌ Firebase init failed: $e');
  }
  initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();

  Hive.registerAdapter(MessageAdapter());
  await Hive.openBox<Message>('messages');
  await Hive.openBox<Map>('syncQueue');



  runApp(
    MultiProvider(
      providers: [ ChangeNotifierProvider(create: (_) => TextDictionaryProvider()..load()
      ),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        Provider<AudioManager>(create: (_) => AudioManager()), // 🔥 추가된 줄
        // 🔽 여기부터 Firestore 경로/레포 주입
        Provider<UserStorePaths>(
          create: (_) => FirestorePathsV1(FirebaseFirestore.instance),
        ),
        // 다른 프로바이더를 의존하는 경우는 ProxyProvider가 안전하다
        ProxyProvider<UserStorePaths, RoutineRepo>(
          update: (_, paths, __) => RoutineRepo(paths),
        ),
   ProxyProvider<UserStorePaths, MessageRepo>(
     update: (_, paths, __) => MessageRepo(paths),
   ),
   ProxyProvider<UserStorePaths, TagRepo>(
     update:  (_, paths, __) => TagRepo(paths),
   ),

        // 🔥 추가
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(ProgressService(ProgressRepo()))..init(),
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
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: user == null ? const LoginScreen() : const TabNav(),
    );
  }
}
