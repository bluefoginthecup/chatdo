import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/tab_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  // 구글 로그인 함수 (앞서 설명한 내용을 기반으로 작성)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }

  // 🔄 로그인 버튼 UI 및 처리
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Center(
        child: _isSigningIn
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Google로 로그인"),
                onPressed: () async {
                  setState(() {
                    _isSigningIn = true;
                  });

                  UserCredential? userCredential = await signInWithGoogle();

                  setState(() {
                    _isSigningIn = false;
                  });

                  if (userCredential != null) {
                    // 🔓 로그인 성공 시 메인 화면으로 전환
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TabNav()),
                    );
                    debugPrint('로그인 성공: ${userCredential.user?.displayName}');
                  } else {
                    // ❌ 실패 시 메시지 표시
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('로그인 실패 또는 취소되었습니다.')),
                    );
                  }
                },
              ),
      ),
    );
  }
}
