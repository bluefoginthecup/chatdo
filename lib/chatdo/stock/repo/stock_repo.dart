import '../models/stock_item.dart';

/// Firestore layout:
/// users/{uid}/stock/{folder}/subs/{sub}/items/{itemId}
abstract class StockRepo {
  // Folders (top-level)
  Stream<List<String>> watchFolders();
  Future<void> createFolder(String folder);
  Future<void> deleteFolder(String folder);

  // Sub-folders
  Stream<List<String>> watchSubs(String folder);
  Future<void> createSub(String folder, String sub);
  Future<void> deleteSub(String folder, String sub);

  // Items
  Stream<List<StockItem>> watchItems(String folder, String sub);
  Future<void> addItem(StockItem item);
  Future<void> updateItem(StockItem item);
  Future<void> deleteItem(String folder, String sub, String id);
}
