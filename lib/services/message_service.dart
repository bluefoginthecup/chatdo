import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

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
  }

  static List<Message> getAllMessages() {
    return _box.values.toList();
  }
}
