import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import 'package:intl/intl.dart';

class DoneListScreen extends StatelessWidget {
  const DoneListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final dones = scheduleProvider.dones;

    return Scaffold(
      appBar: AppBar(title: const Text('완료한 일 목록')),
      body: dones.isEmpty
          ? const Center(child: Text('아직 완료한 일이 없습니다.'))
          : ListView.builder(
        itemCount: dones.length,
        itemBuilder: (context, index) {
          final done = dones[index];
          final dateStr =
          DateFormat('yyyy년 MM월 dd일').format(done.date);
          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(done.content),
            subtitle: Text(dateStr),
          );
        },
      ),
    );
  }
}
