import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploader {
  static Future<List<String>> pickAndUploadImages({
    bool fromCamera = false,
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

    for (final file in pickedFiles) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        '${tempDir.path}/compressed_$fileName',
        quality: 70,
        minWidth: 720,
        minHeight: 720,
        format: CompressFormat.webp,
      );

      final File fileToUpload = compressedFile != null ? File(compressedFile.path) : File(file.path);

      final ref = FirebaseStorage.instance
          .ref('users/$userId/images/$fileName');

      await ref.putFile(fileToUpload, SettableMetadata(contentType: 'image/webp'));
      final url = await ref.getDownloadURL();
      uploadedUrls.add(url);
    }

    return uploadedUrls;
  }
}
