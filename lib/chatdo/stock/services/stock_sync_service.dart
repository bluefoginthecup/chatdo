import '../models/stock_item.dart';
import '../repo/hive_stock_repo.dart';
import '../repo/firebase_stock_repo.dart';

class StockSyncService {
  final HiveStockRepo hiveRepo;
  final FirebaseStockRepo firebaseRepo;

  StockSyncService(this.hiveRepo, this.firebaseRepo);

  Future<void> sync(List<String> categories) async {
    for (final category in categories) {
      // 1. 로컬 dirty 아이템 → 서버 업로드
      final dirtyItems = hiveRepo.getAll(category).where((i) => i.dirty).toList();
      for (final item in dirtyItems) {
        if (item.deleted) {
          await firebaseRepo.delete(item);
        } else {
          await firebaseRepo.upsert(item);
        }
        item.dirty = false;
        await hiveRepo.update(item);
      }

      // 2. 서버 아이템 → 로컬 갱신
      final serverItems = await firebaseRepo.fetch(category);
      for (final s in serverItems) {
        final local = hiveRepo.getAll(category).where((i) => i.id == s.id).toList();
        if (local.isEmpty || s.updatedAt > local.first.updatedAt) {
          await hiveRepo.add(s);
        }
      }
    }
  }
}
