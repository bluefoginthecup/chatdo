import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpeechBubbleComponent extends PositionComponent {
  final double maxWidth;
  final Color bubbleColor;
  final TextStyle textStyle;

  TextBoxComponent? _textBox;
  PositionComponent? _background;
  PolygonComponent? _tail;
  PositionComponent? _target;

  String? get currentText => _textBox?.text;

  SpeechBubbleComponent({
    required String text,
    this.maxWidth = 200,
    this.bubbleColor = Colors.white,
    this.textStyle = const TextStyle(color: Colors.black, fontSize: 18),
    Vector2? position,
  }) {
    this.position = position ?? Vector2.zero();
    _initWithText(text);
  }

  Future<void> _initWithText(String text) async {
    await _buildComponents(text);
  }

  Future<void> _buildComponents(String text) async {
    // 기존 컴포넌트 제거
    _textBox?.removeFromParent();
    _background?.removeFromParent();
    _tail?.removeFromParent();

    // 텍스트박스 생성
    final textBox = TextBoxComponent(
      text: text,
      boxConfig: TextBoxConfig(
        maxWidth: maxWidth,
        timePerChar: 0,
        growingBox: true,
      ),
      textRenderer: TextPaint(style: textStyle),
      position: Vector2(4, 4),
      anchor: Anchor.topLeft,
    );
    await textBox.onLoad(); // 사이즈 계산 위해 필요
    _textBox = textBox;

    final backgroundSize = textBox.size + Vector2(8, 8);
    final background = _RoundedBackground(
      size: backgroundSize,
      color: bubbleColor,
      cornerRadius: 12,
    );
    _background = background;

    final tailTopY = backgroundSize.y;
    final tail = PolygonComponent(
      [
        Vector2(100, tailTopY),
        Vector2(115, tailTopY + 15),
        Vector2(80, tailTopY),
      ],
      paint: Paint()..color = bubbleColor,
    );
    _tail = tail;

    size = backgroundSize + Vector2(0, 15);
    addAll([background, tail, textBox]);

    _reposition(); // 크기 바뀐 뒤 위치도 갱신
  }

  void updateText(String newText) async {
    await _buildComponents(newText);
  }

// ✅ 새로 추가
  void show(String text) {
    updateText(text);
  }


  PositionComponent? attachedTo;

  void attachTo(PositionComponent target) {
    _target = target;
    attachedTo = target;
    _reposition();
  }

  void _reposition() {
    if (_target != null) {
      final adjusted = _target!.position - Vector2(100, _target!.size.y / 2 + size.y - 70);
      position = adjusted;
      print('🗯️ SpeechBubble repositioned to: $position, size: $size');
    }
  }

  static SpeechBubbleComponent createFor(PositionComponent target, List<String> dialogueList) {
    final bubble = SpeechBubbleComponent(
      text: dialogueList.isNotEmpty ? dialogueList.first : '',
      maxWidth: 220,
      bubbleColor: Colors.white,
      textStyle: const TextStyle(color: Colors.black, fontSize: 24),
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
