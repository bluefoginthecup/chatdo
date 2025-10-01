// This file provides a manual TypeAdapter so you don't need build_runner.
part of 'stock_item.dart';

class StockItemAdapter extends TypeAdapter<StockItem> {
  @override
  final int typeId = 1; // ✅ 예전 저장본(typeId: 33)에 맞춤. 다르면 과거 값으로 바꾸세요.

  // 🔧 관대한 캐스팅 헬퍼들
  String _asString(dynamic v) =>
      v is String ? v : (v != null ? v.toString() : '');
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return false;
  }

  @override
  StockItem read(BinaryReader reader) {
    // g.dart 스타일: fields 맵으로 읽기 (필드 순서/추가 변화에 강함)
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return StockItem(
      id: _asString(fields[0]), // 기존엔 as String이었음 → 안전 캐스팅
      folder: _asString(fields[1]),
      sub: _asString(fields[2]),
      name: _asString(fields[3]),
      qty: _asInt(fields[4]),
      updatedAt: _asInt(fields[5]), // millis 등 int로 저장되었다면 그대로 int 유지
      deleted: _asBool(fields[6]),
      dirty: _asBool(fields[7]),
    );
  }

  @override
  void write(BinaryWriter writer, StockItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folder)
      ..writeByte(2)
      ..write(obj.sub)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.qty)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.deleted)
      ..writeByte(7)
      ..write(obj.dirty);
  }
}
