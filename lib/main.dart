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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();
  Hive.registerAdapter(MessageAdapter());
  await Hive.openBox<Message>('messages');
  await Hive.openBox<Map>('syncQueue');

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
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'ChatDo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: user == null ? const LoginScreen() : const MainTabController(),
    );
  }
}
