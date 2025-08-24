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
import 'chatdo/services/auto_postpone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



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

  final prefs = await SharedPreferences.getInstance();
  final isAutoPostponeEnabled = prefs.getBool('auto_postpone_enabled') ?? false;

  if (isAutoPostponeEnabled) {
    await AutoPostponeService.runIfNeeded();// 🔁 자동 미루기 함수
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        Provider<AudioManager>(create: (_) => AudioManager()), // 🔥 추가된 줄
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
