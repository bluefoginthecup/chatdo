import 'package:flutter/material.dart';
import '../repo/stock_repo.dart';
import 'stock_items_screen.dart';

class StockSubListScreen extends StatelessWidget {
  final StockRepo repo;
  final String folder;
  const StockSubListScreen(
      {super.key, required this.repo, required this.folder});

  Future<void> _newSub(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('[$folder] 하위 폴더 만들기'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예) 에리카 화이트')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('확인')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) await repo.createSub(folder, name);
  }

  Future<void> _deleteFolder(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: const Text('정말 삭제하시겠습니까? (하위 폴더 및 아이템이 모두 삭제됩니다)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      await repo.deleteFolder(folder);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folder),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteFolder(context)),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: repo.watchSubs(folder),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final subs = snap.data!;
          if (subs.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: () => _newSub(context),
                icon: const Icon(Icons.create_new_folder),
                label: const Text('하위 폴더 만들기'),
              ),
            );
          }
          return ListView.separated(
            itemCount: subs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = subs[i];
              return ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(s),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('하위 폴더 삭제'),
                            content: const Text('정말 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제')),
                            ],
                          ),
                        );
                        if (ok == true) await repo.deleteSub(folder, s);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockItemsScreen(
                                  repo: repo, folder: folder, sub: s),
                            ));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newSub(context),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('새폴더+'),
      ),
    );
  }
}
