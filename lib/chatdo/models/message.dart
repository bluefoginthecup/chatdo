import 'package:hive/hive.dart';

part 'message.g.dart'; // build_runner로 생성될 파일

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  String type; // 할일 / 한일

  @HiveField(3)
  String date; // 예: 2025-04-15

  @HiveField(4)
  int timestamp;

  Message({
    required this.id,
    required this.text,
    required this.type,
    required this.date,
    required this.timestamp,
  });
}
