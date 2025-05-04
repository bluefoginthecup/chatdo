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
    bool fromCamera = false,
    void Function(int done, int total)? onProgress,
  }) async {
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

    return uploadedUrls;
  }

  static Future<String?> editAndReuploadImage(BuildContext context, File originalFile) async {
    checkFormat(originalFile); // ✅ 편집기 들어가기 전 포맷 확인

    // 🔁 1. File → bytes → decode → re-encode (JPEG)
    final originalBytes = await originalFile.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) throw Exception("디코딩 실패");

    final jpgBytes = img.encodeJpg(decoded, quality: 90);  // progressive 없이
    final tempDir = Directory.systemTemp;
    final safePath = '${tempDir.path}/safe_for_editor.jpg';
    final safeFile = File(safePath)..writeAsBytesSync(jpgBytes);

    // ✅ 확인용 로그
    checkFormat(safeFile);

    // 🔁 2. File 기반으로 편집기 실행
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageEditor(image: safeFile)),
    );

    if (result == null || result is! Uint8List) return null;
    final bytes = result as Uint8List;

    // 🔁 3. 편집 결과를 파일로 저장
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_edited.jpg';
    final outputPath = '${tempDir.path}/$fileName';
    final editedFile = await File(outputPath).writeAsBytes(bytes);

    checkFormat(editedFile); // ✅ 편집 끝나고 포맷 확인

    // 🔁 4. Firebase 업로드
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref('users/$userId/images/$fileName');

    await ref.putFile(editedFile, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
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
