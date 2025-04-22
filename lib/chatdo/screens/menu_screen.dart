// lib/chatdo/screens/menu_screen.dart
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메뉴')),
      body: const Center(
        child: Text('메뉴 화면입니다. 여기에 설정이나 기타 기능을 넣을 수 있어요.'),
      ),
    );
  }
}
