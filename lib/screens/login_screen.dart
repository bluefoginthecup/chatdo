import 'package:flutter/material.dart';
import '../auth_service.dart';// AuthService 임포트
import 'home_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // AuthService 인스턴스

    return Scaffold(
      appBar: AppBar(title: const Text('Google 로그인')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // 구글 로그인 처리
            User? user = await authService.signInWithGoogle();
            if (user != null) {
              // 로그인 성공 시, 홈 화면으로 이동
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeChatScreen()),
              );
            } else {
              // 로그인 실패 시, 실패 메시지 출력
              print('로그인 실패');
            }
          },
          child: const Text('구글로 로그인'),
        ),
      ),
    );
  }
}
