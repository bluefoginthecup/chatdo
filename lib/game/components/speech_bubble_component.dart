import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A reusable speech bubble component with background and tail, supporting multiline text.
class SpeechBubbleComponent extends PositionComponent {
  final String text;
  final double maxWidth;
  final Color bubbleColor;
  final TextStyle textStyle;

  TextBoxComponent? _textBox;
  PolygonComponent? _tail;

  String? get currentText => _textBox?.text;

  SpeechBubbleComponent({
    required this.text,
    this.maxWidth = 200,
    this.bubbleColor = Colors.white,
    this.textStyle = const TextStyle(color: Colors.black, fontSize: 18),
    Vector2? position,
  }) {
    this.position = position ?? Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final textBox = TextBoxComponent(
      text: text,
      boxConfig: TextBoxConfig(
        maxWidth: maxWidth,
        timePerChar: 0,
        growingBox: true,
      ),
      textRenderer: TextPaint(style: textStyle),
      position: Vector2(4, 4), // 🔹 내부 여백 줄이기
      anchor: Anchor.topLeft,
    );
    await textBox.onLoad();
    _textBox = textBox;

    final backgroundSize = textBox.size + Vector2(8, 8); // 🔹 여백 줄임

    final background = _RoundedBackground(
      size: backgroundSize,
      color: bubbleColor,
      cornerRadius: 12, // 🔹 좀 더 둥근 테두리
    );

    final tailTopY = backgroundSize.y;
    final tail = PolygonComponent(
      [
        Vector2(40, tailTopY),
        Vector2(55, tailTopY + 15),
        Vector2(70, tailTopY),
      ],
      paint: Paint()..color = bubbleColor,
    );
    _tail = tail;

    size = backgroundSize + Vector2(0, 15);

    addAll([background, tail, textBox]);
  }

  void updateText(String newText) {
    if (_textBox != null) {
      _textBox!.text = newText;
      _textBox!.position = Vector2(8, 8);
      _textBox!.onLoad(); // 강제 리로드로 size 재계산

      final newBackgroundSize = _textBox!.size + Vector2(16, 16);
      size = newBackgroundSize + Vector2(0, 15);

      // 꼬리 재생성 후 교체
      _tail?.removeFromParent();
      final tailTopY = newBackgroundSize.y;
      _tail = PolygonComponent(
        [
          Vector2(40, tailTopY),
          Vector2(55, tailTopY + 15),
          Vector2(70, tailTopY),
        ],
        paint: Paint()..color = bubbleColor,
      );
      add(_tail!);
    }
  }

  /// Automatically positions the speech bubble above a target component
  void attachTo(PositionComponent target) {
    final adjusted = target.position - Vector2(100, target.size.y / 2 + size.y + 70);
    position = adjusted;
    print('🗯️ SpeechBubble attached at: $position, $size');
  }

  static SpeechBubbleComponent createFor(PositionComponent target, List<String> dialogueList) {
    final bubble = SpeechBubbleComponent(
      text: dialogueList.isNotEmpty ? dialogueList.first : '',
      maxWidth: 220,
      bubbleColor: Colors.white,
      textStyle: const TextStyle(color: Colors.black, fontSize: 18),
    )..priority = 1000;

    bubble.attachTo(target);
    return bubble;
  }
}
class _RoundedBackground extends PositionComponent {
  final Color color;
  final double cornerRadius;

  _RoundedBackground({
    required Vector2 size,
    required this.color,
    this.cornerRadius = 12,
  }) {
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = color;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rrect, paint);
  }
}
