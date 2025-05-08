import 'dart:convert';


class ContentBlock {
  final String type; // 'text' or 'image'
  final String data;


  ContentBlock({required this.type, required this.data});

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
  };

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] ?? 'text',
      data: json['data'] ?? '',
    );
  }

  @override
  String toString() => 'ContentBlock(type: $type, data: $data)';

  static String buildJsonBody({
    required String text,
    required List<String> imageUrls,
  }) {
    final List<ContentBlock> blocks = [];

    if (text.trim().isNotEmpty) {
      blocks.add(ContentBlock(type: 'text', data: text.trim()));
    }

    for (final url in imageUrls) {
      blocks.add(ContentBlock(type: 'image', data: url));
    }

    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }

}
