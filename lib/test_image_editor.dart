import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FirestoreImageEditorApp());
}

class FirestoreImageEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirestoreImageEditor(),
    );
  }
}

class FirestoreImageEditor extends StatefulWidget {
  @override
  State<FirestoreImageEditor> createState() => _FirestoreImageEditorState();
}

class _FirestoreImageEditorState extends State<FirestoreImageEditor> {
  Uint8List? edited;
  String? imageUrl;
  Future<void> fetchAndEditImageById() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('messages')
          .doc('QNsm8d9axxZNpzZSuIiQxaqi0vQ2')
          .collection('logs')
          .doc('nS7nvcBtZIjR8yOzrCTL')
          .get();

      if (!doc.exists) throw Exception('문서 없음');

      final data = doc.data();
      final List<dynamic>? urls = data?['imageUrls'];

      if (urls == null || urls.isEmpty) throw Exception('imageUrls 없음');

      final imageUrl = urls.first;
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('이미지 다운로드 실패');

      final imageBytes = response.bodyBytes;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: imageBytes),
        ),
      );

      if (result != null && result is Uint8List) {
        setState(() {
          edited = result;
        });
      }
    } catch (e) {
      print('에러 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러: ${e.toString()}')),
      );
    }
  }

  /// ✅ 이미지 보기만
  Future<void> fetchImageUrlOnly() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('logs') // 🔁 messages/X/logs → logs 루트로 바꿈
        .orderBy('timestamp', descending: true)
        .get();

    for (final doc in snapshot.docs) {
      final urls = doc.data()['imageUrls'];
      if (urls != null && urls is List && urls.isNotEmpty) {
        setState(() {
          imageUrl = urls.first;
        });
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("이미지를 포함한 문서를 찾을 수 없습니다")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firestore 이미지 테스트")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: fetchAndEditImageById,
            child: Text("특졍문서에서 이미지 편집"),
          ),
          ElevatedButton(
            onPressed: fetchImageUrlOnly,
            child: Text("Firestore에서 이미지 보기"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('logs')
                  .add({
                'test': 'Hello from app',
                'timestamp': Timestamp.now(),
                'imageUrls': [
                  'https://firebasestorage.googleapis.com/v0/b/chatdo-48bf4.firebasestorage.app/o/chat_images%2FQNsm8d9axxZNpzZSuIiQxaqi0vQ2%2F1746335196090.jpg?alt=media&token=a82ea0b7-0b09-46b1-9015-57cbc17ce073', // 샘플 이미지 URL
                ],
              });
              print("테스트 문서 업로드 완료");
            },
            child: Text("테스트 문서 업로드"),
          ),

          if (edited != null)
            Expanded(child: Image.memory(edited!))
          else
            Expanded(child: Center(child: Text("편집된 이미지 없음"))),
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(imageUrl!),
            ),
        ],
      ),
    );
  }
}
