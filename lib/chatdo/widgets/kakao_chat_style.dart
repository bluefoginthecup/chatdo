// kakao_chat_style.dart
import 'package:flutter/material.dart';

class KakaoTokens {
  // Colors
  static const bg = Color(0xFFEDEDED);
  static const bubbleMine = Colors.transparent; // 내 말풍선 색 (원래 카톡 노랑: 0xFFFFE94D)
  static const bubbleOther = Colors.white;
  static const text = Color(0xFF111111);
  static const time = Color(0xFF9AA0A6);
  static const tagFg = Color(0xFFF4EDED);
  static const tagBg = Color(0xC8E65F17);
  // Tag spacing (추가)
  static const tagSpacingH = 6.0; // 태그 칩들 사이 가로 간격
  static const tagSpacingV = 4.0; // 줄바꿈 시 세로 간격(줄 간격) ← 여기 숫자만 바꾸면 됨

  static const contentBoxBg = Color(0xADFFC506);
  static const overlay = Colors.black45;

  // Radii
  static const bubbleRadius = 14.0;
  static const contentBoxRadius = 8.0;
  static const mainImageRadius = 10.0;
  static const thumbRadius = 8.0;

  // Paddings
  static const padH = 10.0; // bubble H
  static const padV = 8.0;  // bubble V

  // Content paddings
  static const contentPadH = 6.0;
  static const contentPadV = 8.0;
  static const chipPadH = 8.0;
  static const chipPadV = 4.0;

  // Sizes
  static const maxWidthFactor = 0.72;
  static const thumbSize = 110.0;
  static const timeFontSize = 11.0;
  static const messageFontSize = 15.0;
  static const tagFontSize = 12.0;

  // Gaps (spacing scale)
  static const gap2 = 2.0;
  static const gap4 = 4.0;
  static const gap6 = 6.0;
  static const gap8 = 8.0;

  // Loaders
  static const loaderSize = 22.0;

  // Images
  static const imageFit = BoxFit.cover;

  // Bubble tail
  static const tailOffset = 6.0;    // 좌/우로 살짝 튀어나오는 오프셋
  static const tailWidth  = 12.0;
  static const tailHeight = 10.0;
}

// Common constraints & sizes
BoxConstraints kakaoMaxBubbleConstraints(BuildContext c) =>
    BoxConstraints(maxWidth: MediaQuery.of(c).size.width * KakaoTokens.maxWidthFactor);

double kakaoMainImageWidth(BuildContext c) =>
    MediaQuery.of(c).size.width * KakaoTokens.maxWidthFactor;

// Text styles
class KakaoText {
  static const message = TextStyle(
    fontSize: KakaoTokens.messageFontSize,
    height: 1.35,
    color: KakaoTokens.text,
  );
  static const tag = TextStyle(
    fontSize: KakaoTokens.tagFontSize,
    color: KakaoTokens.tagFg,
  );
  static const time = TextStyle(
    fontSize: KakaoTokens.timeFontSize,
    color: KakaoTokens.time,
  );
}

// Gaps (수평/수직 간격)
class KakaoGap {
  static const v2 = SizedBox(height: KakaoTokens.gap2);
  static const v4 = SizedBox(height: KakaoTokens.gap4);
  static const v6 = SizedBox(height: KakaoTokens.gap6);
  static const v8 = SizedBox(height: KakaoTokens.gap8);

  static const h2 = SizedBox(width: KakaoTokens.gap2);
  static const h4 = SizedBox(width: KakaoTokens.gap4);
  static const h6 = SizedBox(width: KakaoTokens.gap6);
  static const h8 = SizedBox(width: KakaoTokens.gap8);
}

// 시간
class KakaoTime extends StatelessWidget {
  final String text;
  const KakaoTime(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: KakaoTokens.gap6,
      right: KakaoTokens.gap6,
      top: KakaoTokens.gap4,
    ),
    child: Text(text, style: KakaoText.time),
  );
}

// 라인(정렬 + 투명 박스)
class KakaoLine extends StatelessWidget {
  final bool isMe;
  final Widget child;
  const KakaoLine({super.key, required this.isMe, required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          vertical: KakaoTokens.gap4,
          horizontal: KakaoTokens.gap8 + 2.0, // 미묘한 여백
        ),
        child: child,
      ),
    );
  }
}

// 말풍선 (꼬리 포함)
class KakaoBubble extends StatelessWidget {
  final bool isMe;
  final Widget child;
  const KakaoBubble({super.key, required this.isMe, required this.child});
  @override
  Widget build(BuildContext context) {
    final color = isMe ? KakaoTokens.bubbleMine : KakaoTokens.bubbleOther;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(KakaoTokens.bubbleRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: KakaoTokens.padH,
            vertical: KakaoTokens.padV,
          ),
          child: child,
        ),
        Positioned(
          bottom: KakaoTokens.gap2,
          right: isMe ? -KakaoTokens.tailOffset : null,
          left: isMe ? null : -KakaoTokens.tailOffset,
          child: CustomPaint(
            size: Size(KakaoTokens.tailWidth, KakaoTokens.tailHeight),
            painter: _BubbleTailPainter(color: color, isRight: isMe),
          ),
        ),
      ],
    );
  }
}
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isRight;
  const _BubbleTailPainter({required this.color, required this.isRight});

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    final path = Path();
    if (isRight) {
      path
        ..moveTo(0, s.height)
        ..quadraticBezierTo(s.width * 0.1, s.height * 0.2, s.width, 0)
        ..lineTo(0, 0)
        ..close();
    } else {
      path
        ..moveTo(s.width, s.height)
        ..quadraticBezierTo(s.width * 0.9, s.height * 0.2, 0, 0)
        ..lineTo(s.width, 0)
        ..close();
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.isRight != isRight;
}


// 본문 박스
class KakaoMessageBox extends StatelessWidget {
  final String text;
  const KakaoMessageBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KakaoTokens.contentPadH,
        vertical: KakaoTokens.contentPadV,
      ),
      decoration: BoxDecoration(
        color: KakaoTokens.contentBoxBg,
        borderRadius: BorderRadius.circular(KakaoTokens.contentBoxRadius),
      ),
      child: Text(text, style: KakaoText.message),
    );
  }
}

// 태그 칩
class KakaoTagChip extends StatelessWidget {
  final String text;
  const KakaoTagChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KakaoTokens.chipPadH,
        vertical: KakaoTokens.chipPadV,
      ),
      decoration: BoxDecoration(
        color: KakaoTokens.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: KakaoText.tag),
    );
  }
}

// 메인 이미지 프레임
class KakaoMainImageFrame extends StatelessWidget {
  final Widget child;
  const KakaoMainImageFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(KakaoTokens.mainImageRadius),
      child: SizedBox(
        width: kakaoMainImageWidth(context),
        child: child,
      ),
    );
  }
}

// 썸네일 프레임
class KakaoThumbFrame extends StatelessWidget {
  final Widget child;
  const KakaoThumbFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(KakaoTokens.thumbRadius),
      child: SizedBox(
        width: KakaoTokens.thumbSize,
        height: KakaoTokens.thumbSize,
        child: child,
      ),
    );
  }
}

// 업로드 오버레이(로딩)
class KakaoUploadOverlay extends StatelessWidget {
  const KakaoUploadOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: KakaoTokens.overlay,
      child: const Center(
        child: SizedBox(
          width: KakaoTokens.loaderSize,
          height: KakaoTokens.loaderSize,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// 시간 포맷
String formatKakaoTime(DateTime dt) {
  final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour < 12 ? '오전' : '오후';
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$ampm $h12:$mm';
}
// ─────────────────────────────────────────────────────────────────────────────
// 레이아웃 정책: 메시지 맵에서 lane(right/left/center) 자동 결정
class KakaoLayout {
  /// 최종 lane 결정을 반환합니다.
  /// 우선순위: 명시된 lane → 시스템/알림 힌트 → 사용자 힌트 → 기타 역할(왼쪽) → 기본값(right)
  static String laneOf(Map<String, dynamic> msg) {
    final lane = (msg['lane'] as String?)?.toLowerCase().trim();
    if (lane == 'right' || lane == 'left' || lane == 'center') return lane!;

    // 시스템/알림 힌트 → center
    if (msg['isSystem'] == true) return 'center';
    final role = (msg['role'] as String?)?.toLowerCase();
    final source = (msg['source'] as String?)?.toLowerCase();
    if (role == 'system' || role == 'reminder' || role == 'notice') return 'center';
    if (source == 'calendar' || source == 'scheduler' || msg.containsKey('deliverAt')) {
      return 'center';
    }

    // 사용자(내) 힌트 → right
    if (role == 'me' || role == 'user' || role == 'self') return 'right';
    if (msg['isMe'] == true) return 'right';
    final from = (msg['from'] as String?)?.toLowerCase();
    if (from == 'me' || from == 'user' || from == 'self' || from == 'composer') return 'right';

    // 기타 역할/봇(조르디 등) → left
    if (role != null && role.isNotEmpty) return 'left';

    // 기본값: 사용자 메시지로 가정 → right
    return 'right';
  }

  static bool isMe(Map<String, dynamic> msg) => laneOf(msg) == 'right';
  static bool isSystem(Map<String, dynamic> msg) => laneOf(msg) == 'center';
}
