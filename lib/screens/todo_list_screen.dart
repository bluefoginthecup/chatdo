import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import 'package:intl/intl.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final todos = scheduleProvider.todos;

    return Scaffold(
      appBar: AppBar(title: const Text('할일 목록')),
      body: todos.isEmpty
          ? const Center(child: Text('등록된 할일이 없습니다.'))
          : ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          final dateStr =
          DateFormat('yyyy년 MM월 dd일').format(todo.date);
          return ListTile(
            leading: Checkbox(
              value: false,
              onChanged: (bool? checked) {
                if (checked == true) {
                  // 체크되었을 때, 할일을 한일로 이동
                  scheduleProvider.moveToDone(todo);
                }
              },
            ),
            title: Text(todo.content),
            subtitle: Text(dateStr),
          );
        },
      ),
    );
  }
}
