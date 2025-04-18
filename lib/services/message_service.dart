import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import 'sync_service.dart'; // ✅ 반드시 추가

class MessageService {
  static final _uuid = Uuid();
  static final _box = Hive.box<Message>('messages');

  static Future<void> addMessage(String text, String type, String date) async {
    final message = Message(
      id: _uuid.v4(),
      text: text,
      type: type,
      date: date,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _box.add(message);

    // ✅ syncQueue에도 등록
    await SyncService.addEvent("add_message", {
      "id": message.id,
      "text": message.text,
      "type": message.type,
      "date": message.date,
      "timestamp": message.timestamp,
    });
  }

  static List<Message> getAllMessages() {
    return _box.values.toList();
  }
}
