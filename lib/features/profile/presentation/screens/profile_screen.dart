import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/game/progress/progress_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final p = context.watch<ProgressProvider>(); // totals 읽기

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.displayName ?? '이름 없음'),
            subtitle: Text(user?.email ?? '이메일 없음'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 28),
                      const SizedBox(height: 6),
                      Text('XP', style: Theme.of(context).textTheme.labelLarge),
                      Text('${p.totals.xp}', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 28),
                      const SizedBox(height: 6),
                      Text('Gold', style: Theme.of(context).textTheme.labelLarge),
                      Text('${p.totals.gold}', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // (선택) 초기화/디버그용 버튼
          FilledButton.tonal(
            onPressed: () async {
              // 간단 초기화: 0으로 덮기 (서비스에 reset 추가 안 했으면 임시로 award 안 쓰고 저장소 직접 접근 권장X)
              final prov = context.read<ProgressProvider>();
              // 안전하게 reset API를 provider에 하나 추가해두는 걸 추천:
              // await prov.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초기화 기능은 추후 추가(Provider.reset)')),
              );
            },
            child: const Text('XP/Gold 초기화(디버그)'),
          ),
        ],
      ),
    );
  }
}
