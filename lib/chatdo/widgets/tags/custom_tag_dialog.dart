import 'package:flutter/material.dart';

Future<String?> showCustomTagDialog(BuildContext context) async {
  String tag = '';

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('새 태그 입력'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => tag = value,
          decoration: const InputDecoration(
            hintText: '예: 납품, 공방일, 발주',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context, tag.trim()),
          ),
        ],
      );
    },
  );
}
