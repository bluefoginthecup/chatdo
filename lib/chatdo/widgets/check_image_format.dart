
import 'dart:io';
import 'package:image/image.dart' as img;

void checkFormat(File file) async {
  final bytes = await file.readAsBytes();

  if (bytes.length < 4) {
    print("파일이 너무 작아서 판별 불가");
    return;
  }

  // 시그니처 확인
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    print("진짜 JPG임");
  } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    print("PNG임");
  } else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
    print("WEBP 또는 RIFF 기반 포맷");
  } else {
    print("알 수 없는 포맷");
  }

  // 디코딩 확인
  final decoded = img.decodeImage(bytes);
  if (decoded != null) {
    print("✅ 디코딩 가능 (포맷: ${decoded.format.name})");
  } else {
    print("❌ 디코딩 불가 - 포맷이 깨졌거나 비정상일 수 있음");
  }
}
