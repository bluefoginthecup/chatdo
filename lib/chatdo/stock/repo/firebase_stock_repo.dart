import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item.dart';
import 'stock_repo.dart';

class FirebaseStockRepo implements StockRepo {
  final FirebaseFirestore db;
  final String uid;
  FirebaseStockRepo(this.db, this.uid);

  CollectionReference<Map<String, dynamic>> foldersCol() =>
      db.collection('users').doc(uid).collection('stock');

  DocumentReference<Map<String, dynamic>> folderDoc(String folder) =>
      foldersCol().doc(folder);

  CollectionReference<Map<String, dynamic>> subsCol(String folder) =>
      folderDoc(folder).collection('subs');

  DocumentReference<Map<String, dynamic>> subDoc(String folder, String sub) =>
      subsCol(folder).doc(sub);

  CollectionReference<Map<String, dynamic>> itemsCol(String folder, String sub) =>
      subDoc(folder, sub).collection('items');

  // ---- folders ----
  @override
  Stream<List<String>> watchFolders() {
    return foldersCol().orderBy('createdAt', descending: false).snapshots()
      .map((s) => s.docs.map((d)=>d.id).toList());
  }

  @override
  Future<void> createFolder(String folder) async {
    final doc = folderDoc(folder);
    if ((await doc.get()).exists) return;
    await doc.set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> deleteFolder(String folder) async {
    final subs = await subsCol(folder).get();
    final batch = db.batch();
    for (final s in subs.docs) {
      final items = await itemsCol(folder, s.id).get();
      for (final it in items.docs) { batch.delete(it.reference); }
      batch.delete(s.reference);
    }
    batch.delete(folderDoc(folder));
    await batch.commit();
  }

  // ---- subs ----
  @override
  Stream<List<String>> watchSubs(String folder) {
    return subsCol(folder).orderBy('createdAt', descending: false).snapshots()
      .map((s)=> s.docs.map((d)=>d.id).toList());
  }

  @override
  Future<void> createSub(String folder, String sub) async {
    final d = subDoc(folder, sub);
    if ((await d.get()).exists) return;
    await d.set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> deleteSub(String folder, String sub) async {
    final items = await itemsCol(folder, sub).get();
    final batch = db.batch();
    for (final it in items.docs) { batch.delete(it.reference); }
    batch.delete(subDoc(folder, sub));
    await batch.commit();
  }

  // ---- items ----
  @override
  Stream<List<StockItem>> watchItems(String folder, String sub) {
    return itemsCol(folder, sub).orderBy('updatedAt', descending: true).snapshots()
      .map((s)=> s.docs.map((d)=> StockItem.fromFirestore(d.data())).toList());
  }

  @override
  Future<void> addItem(StockItem item) async {
    await itemsCol(item.folder, item.sub).doc(item.id).set(item.toFirestore());
  }

  @override
  Future<void> updateItem(StockItem item) async {
    await itemsCol(item.folder, item.sub).doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteItem(String folder, String sub, String id) async {
    await itemsCol(folder, sub).doc(id).delete();
  }
}
