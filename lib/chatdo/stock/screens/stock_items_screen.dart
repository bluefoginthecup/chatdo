import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../repo/stock_repo.dart';
import '../models/stock_item.dart';

class StockItemsScreen extends StatelessWidget {
  final StockRepo repo;
  final String folder;
  final String sub;
  const StockItemsScreen({super.key, required this.repo, required this.folder, required this.sub});

  Future<void> _addItem(BuildContext context) async {
    final nameC = TextEditingController();
    final qtyC  = TextEditingController(text: '10');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('[$folder / $sub] 재고 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: '품목명 (예: 30x50쿠션커버)')),
            TextField(controller: qtyC, decoration: const InputDecoration(labelText: '수량'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('취소')),
          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('저장')),
        ],
      ),
    );
    if (ok!=true) return;

    final id = const Uuid().v4();
    final qty = int.tryParse(qtyC.text.trim()) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = StockItem(
      id: id,
      folder: folder,
      sub: sub,
      name: nameC.text.trim(),
      qty: qty,
      updatedAt: now,
      deleted: false,
      dirty: true,
    );
    await repo.addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$folder / $sub')),
      body: StreamBuilder<List<StockItem>>(
        stream: repo.watchItems(folder, sub),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('아이템이 없습니다. (아래 버튼으로 추가)'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              return ListTile(
                title: Text(it.name),
                subtitle: Text('수량: ${it.qty}   •   ${DateTime.fromMillisecondsSinceEpoch(it.updatedAt)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('아이템 삭제'),
                        content: const Text('삭제하시겠습니까?'),
                        actions: [
                          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('취소')),
                          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('삭제')),
                        ],
                      ),
                    );
                    if (ok==true) await repo.deleteItem(folder, sub, it.id);
                  },
                ),
                onTap: () async {
                  // quick +1
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final updated = StockItem(
                    id: it.id,
                    folder: it.folder,
                    sub: it.sub,
                    name: it.name,
                    qty: it.qty + 1,
                    updatedAt: now,
                    deleted: it.deleted,
                    dirty: true,
                  );
                  await repo.updateItem(updated);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ()=>_addItem(context),
        icon: const Icon(Icons.add),
        label: const Text('재고 입력'),
      ),
    );
  }
}
