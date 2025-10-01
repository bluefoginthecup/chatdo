import 'package:flutter/material.dart';

class TextBlockWidget extends StatefulWidget {
  final TextEditingController controller;
  final Widget? dragHandle;
  final VoidCallback? onDelete;
  final bool isEditing;
  final void Function(String) onChanged;

  const TextBlockWidget({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.onChanged,
    this.dragHandle,
    this.onDelete,
  });

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      debugPrint("👁 Focus changed: ${_focusNode.hasFocus}");
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🧱 TextBlockWidget build() - isEditing: ${widget.isEditing}");
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isEditing && widget.dragHandle != null) widget.dragHandle!,
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: widget.isEditing
                    ? BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: widget.isEditing
                    ? TextField(
                        controller: widget.controller, // ✅ 이거 반드시 넣어야 텍스트 보임
                        focusNode: _focusNode,
                        onTap: () => debugPrint('🖱 TextField tapped'),
                        onChanged: (v) {
                          debugPrint("✍️ onChanged: $v");
                          widget.onChanged(v);
                        },
                        maxLines: null,
                        decoration: const InputDecoration.collapsed(
                            hintText: '내용을 입력하세요'),
                        style: const TextStyle(fontSize: 16),
                      )
                    : Text(
                        // ✅ 편집모드 아닐 때는 Text 위젯으로 보여주기
                        widget.controller.text,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              if (widget.isEditing && widget.onDelete != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
