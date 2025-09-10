

// lib/game/progress/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../progress_provider.dart';


class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('내 경험치/골드')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('총 경험치: ${p.totals.xp}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('총 골드: ${p.totals.gold}', style: Theme.of(context).textTheme.headlineMedium),
        ]),
      ),
    );
  }
}