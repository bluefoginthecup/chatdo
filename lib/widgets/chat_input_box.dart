import 'package:flutter/material.dart';

class ChatInputBox extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String text) onSubmitted;

  const ChatInputBox({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: onSubmitted,
            decoration: const InputDecoration(
              hintText: '메시지를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          color: Colors.teal,
          onPressed: () => onSubmitted(controller.text),
        )
      ],
    );
  }
}
