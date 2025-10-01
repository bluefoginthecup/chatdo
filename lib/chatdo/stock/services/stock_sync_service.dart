import '../models/stock_item.dart';
import '../repo/stock_repo.dart';

/// Push local dirty changes to Firestore.
class StockSyncService {
  final StockRepo local; // Hive
  final StockRepo remote; // Firebase

  StockSyncService({required this.local, required this.remote});

  Future<void> sync() async {
    final folders = await local.watchFolders().first;
    for (final f in folders) {
      await remote.createFolder(f);
      final subs = await local.watchSubs(f).first;
      for (final s in subs) {
        await remote.createSub(f, s);
        final items = await local.watchItems(f, s).first;
        for (final it in items) {
          if (it.dirty) {
            if (it.deleted) {
              await remote.deleteItem(f, s, it.id);
            } else {
              it.updatedAt = DateTime.now().millisecondsSinceEpoch;
              await remote.updateItem(it);
            }
            it.dirty = false;
            await local.updateItem(it);
          }
        }
      }
    }
  }
}
