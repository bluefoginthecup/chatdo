// lib/models/upload_item.dart
import 'dart:io';

class UploadItem {
  final File file;
  double progress;
  bool isUploading;

  UploadItem({
    required this.file,
    this.progress = 0.0,
    this.isUploading = false,
  });
}
