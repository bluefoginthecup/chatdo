import '../models/stock_item.dart';
import 'stock_repo.dart';

/// UI talks only to local (Hive). Sync service uploads to remote (Firestore).
class HybridStockRepo implements StockRepo {
  final StockRepo local; // HiveStockRepo
  final StockRepo remote; // FirebaseStockRepo (not used directly here)

  HybridStockRepo({required this.local, required this.remote});

  @override
  Stream<List<String>> watchFolders() => local.watchFolders();
  @override
  Future<void> createFolder(String folder) => local.createFolder(folder);
  @override
  Future<void> deleteFolder(String folder) => local.deleteFolder(folder);

  @override
  Stream<List<String>> watchSubs(String folder) => local.watchSubs(folder);
  @override
  Future<void> createSub(String folder, String sub) =>
      local.createSub(folder, sub);
  @override
  Future<void> deleteSub(String folder, String sub) =>
      local.deleteSub(folder, sub);

  @override
  Stream<List<StockItem>> watchItems(String folder, String sub) =>
      local.watchItems(folder, sub);
  @override
  Future<void> addItem(StockItem item) => local.addItem(item);
  @override
  Future<void> updateItem(StockItem item) => local.updateItem(item);
  @override
  Future<void> deleteItem(String folder, String sub, String id) =>
      local.deleteItem(folder, sub, id);
}
