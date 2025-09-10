// lib/game/progress/widgets/xp_toast.dart
import 'package:flutter/material.dart';
import '../progress_models.dart';


void showXPToast(BuildContext context, ProgressDelta d) {
  if (d.isZero) return;
  final msg = '+${d.xp} XP · +${d.gold} G';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)),
  );
}