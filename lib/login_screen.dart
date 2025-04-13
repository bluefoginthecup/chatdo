import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatdo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  // 구글 로그인 함수 (앞서 설명한 내용을 기반으로 작성)
  Future<UserCredential?> signInWithGoogle() async {
    // Google Sign-In 플로우 시작: 사용자 선택 화면 노출
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // 사용자가 로그인 취소 시 null 반환
      return null;
    }

    // 로그인 후 인증 정보를 가져옴
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Firebase와 연동할 자격 증명 생성
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Firebase로 로그인 처리
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

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
              // 로그인 성공 시 다음 화면으로 이동하거나 사용자 정보를 처리합니다.
              // 예시: Navigator.pushReplacement(...)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainTabController()),
              );
              debugPrint('로그인 성공: ${userCredential.user?.displayName}');
            } else {ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인 실패 또는 취소되었습니다.')),
            );
            }
          },
        ),
      ),
    );
  }
}
