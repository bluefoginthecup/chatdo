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
}
