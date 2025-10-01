import 'package:hive/hive.dart';
import '../models/stock_item.dart';
import 'stock_repo.dart';

/// Local-first Hive repository. All UI reads/writes go here first.
class HiveStockRepo implements StockRepo {
  final Box<StockItem> box;
  final Box<List<String>> foldersBox; // keys: 'folders', 'subs:<folder>'

  HiveStockRepo(this.box, this.foldersBox);

  // ---- folders ----
  @override
  Stream<List<String>> watchFolders() async* {
    yield _getFolders();
    yield* foldersBox.watch(key: 'folders').map((_) => _getFolders());
  }

  List<String> _getFolders() => (foldersBox.get('folders') ?? <String>[]).toList();

  @override
  Future<void> createFolder(String folder) async {
    final f = _getFolders();
    if (!f.contains(folder)) {
      f.add(folder);
      await foldersBox.put('folders', f);
    }
  }

  @override
  Future<void> deleteFolder(String folder) async {
    // delete subs & items in this folder
    final subs = _getSubs(folder);
    for (final s in subs) {
      final items = box.values.where((e) => e.folder == folder && e.sub == s).toList();
      for (final it in items) { await it.delete(); }
    }
    await foldersBox.delete('subs:$folder');
    final f = _getFolders()..remove(folder);
    await foldersBox.put('folders', f);
  }

  // ---- subs ----
  @override
  Stream<List<String>> watchSubs(String folder) async* {
    yield _getSubs(folder);
    yield* foldersBox.watch(key: 'subs:$folder').map((_) => _getSubs(folder));
  }

  List<String> _getSubs(String folder) => (foldersBox.get('subs:$folder') ?? <String>[]).toList();

  @override
  Future<void> createSub(String folder, String sub) async {
    final list = _getSubs(folder);
    if (!list.contains(sub)) {
      list.add(sub);
      await foldersBox.put('subs:$folder', list);
    }
  }

  @override
  Future<void> deleteSub(String folder, String sub) async {
    final items = box.values.where((e) => e.folder == folder && e.sub == sub).toList();
    for (final it in items) { await it.delete(); }
    final list = _getSubs(folder)..remove(sub);
    await foldersBox.put('subs:$folder', list);
  }

  // ---- items ----
  @override
  Stream<List<StockItem>> watchItems(String folder, String sub) async* {
    yield _items(folder, sub);
    yield* box.watch().map((_) => _items(folder, sub));
  }

  List<StockItem> _items(String folder, String sub) =>
      box.values.where((e) => e.folder == folder && e.sub == sub && !e.deleted).toList()
         ..sort((a,b)=> b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> addItem(StockItem item) async {
    item.dirty = true;
    await box.put(item.id, item);
  }

  @override
  Future<void> updateItem(StockItem item) async {
    item.dirty = true;
    await box.put(item.id, item);
  }

  @override
  Future<void> deleteItem(String folder, String sub, String id) async {
    final it = box.get(id);
    if (it != null) {
      it.deleted = true;
      it.dirty = true;
      await it.save();
    }
  }
}
