import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMessageCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final void Function(Map<String, dynamic>) onOpenDetail;
  const ChatMessageCard({super.key, required this.msg, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    final content = (msg['content'] as String? ?? '').trim();
    final tags = (msg['tags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final imageUrls = (msg['imageUrls'] as List?)?.cast<String>() ?? const <String>[];
    final firstUrl = (msg['imageUrl'] as String?) ?? (imageUrls.isNotEmpty ? imageUrls.first : null);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onOpenDetail(msg), // 메시지 어디를 눌러도 상세 열기
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1) 제목(텍스트) — 항상 보이게
                if (content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(content),
                  ),

                // 2) 대표 이미지(첫 장)
                if (firstUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: firstUrl,
                        width: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => SizedBox(
                          width: 200, height: 120,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                  ),

                // 3) 썸네일(두 번째 장부터)
                if (imageUrls.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length - 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final url = imageUrls[i + 1];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              width: 110, height: 110, fit: BoxFit.cover,
                              placeholder: (_, __) => const ColoredBox(color: Colors.black12),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // 4) 태그
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6, runSpacing: -6,
                      children: tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black12, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
