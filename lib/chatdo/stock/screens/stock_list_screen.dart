import 'package:flutter/material.dart';
import '../repo/stock_repo.dart';
import 'stock_sub_list_screen.dart';

class StockListScreen extends StatelessWidget {
  final StockRepo repo;
  const StockListScreen({super.key, required this.repo});

  Future<void> _newFolder(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('새 폴더 만들기'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: '예) goods / raw material / sub material')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('확인')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) await repo.createFolder(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('재고목록')),
      body: StreamBuilder<List<String>>(
        stream: repo.watchFolders(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final folders = snap.data!;
          if (folders.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: () => _newFolder(context),
                icon: const Icon(Icons.create_new_folder),
                label: const Text('첫 폴더 만들기'),
              ),
            );
          }
          return ListView.separated(
            itemCount: folders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = folders[i];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(f),
                subtitle: Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text('goods')),
                    Chip(label: Text('raw material')),
                    Chip(label: Text('sub material')),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StockSubListScreen(repo: repo, folder: f),
                        ));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newFolder(context),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('새폴더+'),
      ),
    );
  }
}
