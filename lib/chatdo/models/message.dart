import 'package:hive/hive.dart';

part 'message.g.dart'; // build_runner로 생성될 파일

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String text;
  @HiveField(2) String type;
  @HiveField(3) String date;
  @HiveField(4) int timestamp;

  @HiveField(5) String? imageUrl;

  // ✅ 현재 박스 매핑에 맞춤: 6=tags, 7=imageUrls
  @HiveField(6) List<String>? tags;
  @HiveField(7) List<String>? imageUrls;

  // ✅ 새 필드 전부 nullable
  @HiveField(8) List<String>? localImagePaths;
  @HiveField(9) String? uploadState;  // 'queued'|'uploading'|'done'|'error'

  Message({
    required this.id,
    required this.text,
    required this.type,
    required this.date,
    required this.timestamp,
    this.imageUrl,
    this.tags,
    this.imageUrls,
    this.localImagePaths,
    this.uploadState,
  });

  String get uploadStateSafe => uploadState ?? 'done';

  Message copyWith({
    String? id,
    String? text,
    String? type,
    String? date,
    int? timestamp,
    String? imageUrl,
    List<String>? tags,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    String? uploadState,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      uploadState: uploadState ?? this.uploadState,
    );
  }
}
