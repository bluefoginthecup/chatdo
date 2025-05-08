import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chatdo/chatdo/widgets/check_image_format.dart';
import 'package:image/image.dart' as img;



class ImageUploader {
  static Future<List<String>> pickAndUploadImages({
    required BuildContext context,
    bool fromCamera = false,
    void Function(int done, int total)? onProgress,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final picker = ImagePicker();
    List<XFile> pickedFiles = [];

    if (fromCamera) {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) pickedFiles = [picked];
    } else {
      final picked = await picker.pickMultiImage();
      if (picked != null) pickedFiles = picked;
    }

    if (pickedFiles.isEmpty) return [];

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final tempDir = Directory.systemTemp;
    List<String> uploadedUrls = [];

    for (int i = 0; i < pickedFiles.length; i++) {
      final file = pickedFiles[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final compressedPath = '${tempDir.path}/$fileName';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        compressedPath,
        quality: 70,
        minWidth: 720,
        minHeight: 720,
        format: CompressFormat.jpeg,
      );

      final File fileToUpload = compressedFile != null ? File(compressedFile.path) : File((file as XFile).path);

      final ref = FirebaseStorage.instance
          .ref('users/$userId/images/$fileName');

      await ref.putFile(fileToUpload, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      uploadedUrls.add(url);

      if (onProgress != null) {
        onProgress(i + 1, pickedFiles.length);
      }
    }
    Navigator.pop(context);

    return uploadedUrls;
  }
  static Future<String?> editAndReuploadImage(
      BuildContext context,
      File originalFile,
      String logId,
      ) async {
    debugPrint("🧪 [1] 시작: editAndReuploadImage (간소화 버전)");

    try {
      final imageBytes = await originalFile.readAsBytes();
      debugPrint("📥 [2] 원본 바이트 크기: ${imageBytes.length} bytes");

      // 🔁 이미지 편집기 열기
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: imageBytes),
        ),
      );

      if (result == null || result is! Uint8List) return null;
      final editedBytes = result;

      // 🔁 편집 결과 저장
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_edited.jpg';
      final outputPath = '${appDocDir.path}/$fileName';
      final editedFile = await File(outputPath).writeAsBytes(editedBytes);

      // 🔁 Firebase 업로드
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref('users/$userId/images/$fileName');

      await ref.putFile(editedFile, SettableMetadata(contentType: 'image/jpeg'));

      debugPrint("✅ [3] 업로드 완료: $fileName");
      return await ref.getDownloadURL();

    } catch (e) {
      debugPrint("❌ 에러 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러: ${e.toString()}')),
      );
      return null;
    }
  }


  static Future<File> downloadImageFile(String url) async {
    try {
      debugPrint("🟡 다운로드 시도 URL: $url");

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final rawBytes = response.bodyBytes;

        debugPrint("📦 다운로드된 바이트 크기: ${rawBytes.length} bytes");

        final decoded = img.decodeImage(rawBytes);
        if (decoded == null) {
          throw Exception("이미지를 디코딩할 수 없습니다.");
        }

        final jpgBytes = img.encodeJpg(decoded, quality: 90);  // progressive 없이

        final fixedPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fixedFile = File(fixedPath)..writeAsBytesSync(jpgBytes);

        debugPrint("✅ 변환된 JPG 파일 크기: ${await fixedFile.length()} bytes");
        return fixedFile;
      } else {
        throw Exception('이미지 다운로드 실패. 상태코드: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ downloadImageFile error: $e');
      rethrow;
    }
  }


// JPEG/PNG 파일인지 대략적으로 확인하는 헬퍼
  static bool _isImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // PNG 시그니처: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // JPEG 시그니처: FF D8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    return false;
  }


}
