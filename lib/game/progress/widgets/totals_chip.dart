

// =========================
// 8) UI: 상단 토탈 표시 Chip + 획득 HUD
// =========================
// lib/game/progress/widgets/totals_chip.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../progress_provider.dart';


class TotalsChip extends StatelessWidget {
  const TotalsChip({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressProvider>();
    if (!p.isReady) return const SizedBox.shrink();
    return InputChip(
      label: Row(children:[
        const Icon(Icons.stars, size: 16),
        const SizedBox(width: 6),
        Text('XP ${p.totals.xp}') ,
        const SizedBox(width: 10),
        const Icon(Icons.monetization_on, size: 16),
        const SizedBox(width: 6),
        Text('G ${p.totals.gold}')
      ]),
    );
  }
}