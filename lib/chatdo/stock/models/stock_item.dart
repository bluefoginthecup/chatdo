import 'package:hive/hive.dart';

/// Manual TypeAdapter version (no build_runner required).
part 'stock_item.manual.dart';

@HiveType(typeId: 1) // Ensure this typeId is unique across your app.
class StockItem extends HiveObject {
  @HiveField(0)
  String id; // uuid

  @HiveField(1)
  String folder; // top-level folder, e.g. 'goods'

  @HiveField(2)
  String sub; // sub-folder, e.g. '에리카 화이트'

  @HiveField(3)
  String name; // e.g. '30x50쿠션커버'

  @HiveField(4)
  int qty; // quantity

  @HiveField(5)
  int updatedAt; // epoch ms (last change)

  @HiveField(6)
  bool deleted; // soft-delete flag

  @HiveField(7)
  bool dirty; // needs sync to remote

  StockItem({
    required this.id,
    required this.folder,
    required this.sub,
    required this.name,
    this.qty = 0,
    int? updatedAt,
    this.deleted = false,
    this.dirty = false,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  StockItem copyWith({
    String? id,
    String? folder,
    String? sub,
    String? name,
    int? qty,
    int? updatedAt,
    bool? deleted,
    bool? dirty,
  }) {
    return StockItem(
      id: id ?? this.id,
      folder: folder ?? this.folder,
      sub: sub ?? this.sub,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      dirty: dirty ?? this.dirty,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'folder': folder,
        'sub': sub,
        'name': name,
        'qty': qty,
        'updatedAt': updatedAt,
        'deleted': deleted,
      };

  factory StockItem.fromFirestore(Map<String, dynamic> d) {
    return StockItem(
      id: d['id'] as String,
      folder: d['folder'] as String,
      sub: d['sub'] as String,
      name: d['name'] as String,
      qty: (d['qty'] ?? 0) as int,
      updatedAt: (d['updatedAt'] ?? 0) as int,
      deleted: (d['deleted'] ?? false) as bool,
      dirty: false,
    );
  }
}
