// chat_message_card.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'kakao_chat_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



/// 버킷 문자열 교정(.firebasestorage.app → .appspot.com)
String _fixBucketOnce(String url) {
  return url.replaceFirst(
    '/v0/b/chatdo-48bf4.firebasestorage.app',
    '/v0/b/chatdo-48bf4.appspot.com',
  );
}

/// URL에서 Storage 경로(/o/<encodedPath>)만 뽑아서 디코딩
/// 예) https://.../o/chat_images%2Fuid%2FmsgId%2F0.jpg?alt=media&token=...
///   → chat_images/uid/msgId/0.jpg
String? _storagePathFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  url = _fixBucketOnce(url);
  final m = RegExp(r'/o/([^?]+)').firstMatch(url);
  if (m == null) return null;
  final encoded = m.group(1)!;
  return Uri.decodeComponent(encoded);
}

/// 경로에서 확장자 대체 후보를 만든다 (jpg → jpeg/png/heic도 시도)
List<String> _altExtensionCandidates(String path) {
  final exts = ['.jpg', '.jpeg', '.png', '.heic', '.webp'];
  final dot = path.lastIndexOf('.');
  if (dot < 0) return [path]; // 확장자 없음
  final base = path.substring(0, dot);
  final curExt = path.substring(dot).toLowerCase();

  // 현 확장자 먼저, 나머지 대체
  final ordered = [
    curExt,
    ...exts.where((e) => e != curExt),
  ];
  return ordered.map((e) => '$base$e').toList();
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 원래 URL은 아예 로드하지 않고:
/// 1) URL에서 path만 추출
/// 2) 그 path로 getDownloadURL() 시도
/// 3) 실패하면 확장자 대체 시도
/// 4) 그래도 실패면, 폴더(listAll)에서 아무 파일이나 대표로 선택
class StorageImage extends StatefulWidget {
  final String? originalUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const StorageImage({
    super.key,
    required this.originalUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  String? _resolvedUrl;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUrl != widget.originalUrl) {
      _resolvedUrl = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    final raw = widget.originalUrl;
    if (raw == null || raw.isEmpty) return;

    setState(() => _resolving = true);

    final path = _storagePathFromUrl(raw);
    if (path == null) {
      setState(() => _resolving = false);
      return;
    }

    String? url;

    // 1) 해당 경로 그대로 시도 (확장자 유지)
    try {
      url = await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (_) {
      url = null;
    }

    // 2) 확장자 대체 시도
    if (url == null) {
      for (final candidate in _altExtensionCandidates(path)) {
        try {
          url = await FirebaseStorage.instance.ref(candidate).getDownloadURL();
          if (url != null) break;
        } catch (_) {
          // 계속 시도
        }
      }
    }

    // 3) 폴더로 간주해 listAll()에서 첫 파일 선택
    if (url == null) {
      final asDir = path.endsWith('/') ? path : '$path/'; // 폴더처럼
      try {
        final result = await FirebaseStorage.instance.ref(asDir).listAll();
        if (result.items.isNotEmpty) {
          final picked = result.items.first;
          url = await picked.getDownloadURL();
        }
      } catch (_) {
        // 폴더가 아닐 수도 있음
      }
    }

    // 4) 실패한 이전 URL 캐시 제거 (혹시 남아있다면)
    try {
      if (_resolvedUrl != null) {
        await DefaultCacheManager().removeFile(_resolvedUrl!);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _resolvedUrl = url; // null이면 아래 errorWidget 뜸
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final image = (_resolvedUrl == null)
        ? Container(
      width: widget.width ?? 200,
      height: widget.height ?? 120,
      color: Colors.black12,
      alignment: Alignment.center,
      child: _resolving
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Text('이미지 없음/경로 오류(404)', style: TextStyle(fontSize: 12)),
    )
        : CachedNetworkImage(
      imageUrl: _resolvedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (_, __) => SizedBox(
        width: widget.width ?? 200,
        height: widget.height ?? 120,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: widget.width ?? 200,
        height: widget.height ?? 120,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Text('이미지 없음/경로 오류(404)', style: TextStyle(fontSize: 12)),
      ),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
class ChatMessageCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final void Function(Map<String, dynamic>) onOpenDetail;

  const ChatMessageCard({
    super.key,
    required this.msg,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    // --- 데이터 파싱 (그대로) ---
    final content = (msg['content'] as String? ?? '').trim();
    final tags = (msg['tags'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
        const <String>[];

    final rawImageUrls = (msg['imageUrls'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
        const <String>[];
    final imageUrls = rawImageUrls.map(_fixBucketOnce).where((e) => e.isNotEmpty).toList();

    final firstUrlRaw =
        (msg['imageUrl'] as String?) ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
    final firstUrl = firstUrlRaw != null ? _fixBucketOnce(firstUrlRaw) : null;

    final localPaths = (msg['localImagePaths'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
        const <String>[];
    final firstLocal = localPaths.isNotEmpty ? localPaths.first : null;

    final uploadState = (msg['uploadState'] ?? 'done').toString();
    final uploading = uploadState == 'queued' || uploadState == 'uploading';

    final lane = KakaoLayout.laneOf(msg);
    final bool isMe = lane == 'right';
    final bool isSystem = lane == 'center';

    DateTime? createdAt;
    final rawCreatedAt = msg['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else if (rawCreatedAt is String) {
      try { createdAt = DateTime.parse(rawCreatedAt); } catch (_) {}
    }
    final String? timeText = createdAt != null ? formatKakaoTime(createdAt!) : null;

    // --- 말풍선 내부 컨텐츠 구축 ---
    final List<Widget> bubbleChildren = [];

    if (isSystem) {
      final systemText = content.isNotEmpty
          ? content
          : ((msg['title'] as String?) ?? '알림');

      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KakaoTokens.gap4,
            horizontal: KakaoTokens.gap8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KakaoTokens.chipPadH,
              vertical: KakaoTokens.chipPadV,
            ),
            decoration: BoxDecoration(
              color: KakaoTokens.contentBoxBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(systemText, style: KakaoText.time),
          ),
        ),
      );
    }


    // 본문
    if (content.isNotEmpty) {
      bubbleChildren.add(KakaoMessageBox(content));
    }

    // 대표 이미지
    if (firstUrl != null || firstLocal != null) {
      final Widget main = firstUrl != null
          ? StorageImage(originalUrl: firstUrl, fit: KakaoTokens.imageFit)
          : Image.file(File(firstLocal!), fit: KakaoTokens.imageFit);

      bubbleChildren.add(
        Padding(
          // const 빼도 됩니다. (const 유지해도 컴파일 OK)
          padding: EdgeInsets.only(top: KakaoTokens.gap6),
          child: Stack(
            children: [
              KakaoMainImageFrame(child: main),
              if (uploading) const Positioned.fill(child: KakaoUploadOverlay()),
            ],
          ),
        ),
      );
    }

    // 썸네일(두 번째 장부터)
    final int remoteExtra = imageUrls.length > 1 ? imageUrls.length - 1 : 0;
    final int localExtra  = localPaths.length > 1 ? localPaths.length - 1 : 0;
    final int additionalCount = remoteExtra + localExtra;

    if (additionalCount > 0) {
      bubbleChildren.add(
        Padding(
          padding: EdgeInsets.only(top: KakaoTokens.gap6),
          child: SizedBox(
            height: KakaoTokens.thumbSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => KakaoGap.h8,
              itemCount: additionalCount,
              itemBuilder: (_, int i) {
                final bool isRemote = i < remoteExtra;
                if (isRemote) {
                  // 원격 썸네일(대표 제외 → i+1)
                  return KakaoThumbFrame(
                    child: StorageImage(
                      originalUrl: imageUrls[i + 1],
                      fit: KakaoTokens.imageFit,
                    ),
                  );
                } else {
                  // 로컬 썸네일(대표 제외 → +1부터)
                  final int localIdx = (i - remoteExtra) + 1;
                  if (localIdx >= 0 && localIdx < localPaths.length) {
                    return KakaoThumbFrame(
                      child: Image.file(
                        File(localPaths[localIdx]),
                        fit: KakaoTokens.imageFit,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      );
    }



    // 말풍선 + 시간
    final bubble = KakaoBubble(
      isMe: isMe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [   if (tags.isNotEmpty) ...[
          Wrap(
            spacing: KakaoTokens.tagSpacingH,
            runSpacing: KakaoTokens.tagSpacingV, // ✅ 줄 간격 여기서 조절
            children: tags.map((t) => KakaoTagChip(t)).toList(),
          ),
          KakaoGap.v6,
        ],
    ...bubbleChildren,
    ],  ),
    );

    final line = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isMe
          ? [
        if (timeText != null) KakaoTime(timeText!),
        Flexible(
          child: ConstrainedBox(
            constraints: kakaoMaxBubbleConstraints(context),
            child: bubble,
          ),
        ),
      ]
          : [
        Flexible(
          child: ConstrainedBox(
            constraints: kakaoMaxBubbleConstraints(context),
            child: bubble,
          ),
        ),
        if (timeText != null) KakaoTime(timeText!),
      ],
    );

    return GestureDetector(
      onTap: () => onOpenDetail(msg),
      child: KakaoLine(isMe: isMe, child: line),
    );
  }



}
