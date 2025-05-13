import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A reusable speech bubble component with background and tail, supporting multiline text.
class SpeechBubbleComponent extends PositionComponent {
  final String text;
  final double maxWidth;
  final Color bubbleColor;
  final TextStyle textStyle;

  TextBoxComponent? _textBox;
  RectangleComponent? _background;
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
      position: Vector2(16, 16),
      anchor: Anchor.topLeft,
    );
    await textBox.onLoad();
    _textBox = textBox;

    final backgroundSize = textBox.size + Vector2(32, 32);
    final background = RectangleComponent(
      size: backgroundSize,
      paint: Paint()..color = bubbleColor,
      anchor: Anchor.topLeft,
    );
    _background = background;

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

  /// Updates the text content dynamically
  void updateText(String newText) {
    _textBox?.text = newText;
  }

  /// Positions the speech bubble above the target component
  void attachTo(PositionComponent target, {double offsetY = 100}) {
    position = target.position.clone() - Vector2(0, offsetY);
  }
}
