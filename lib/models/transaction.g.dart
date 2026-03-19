// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      type: fields[1] as String,
      amount: fields[2] as double,
      currency: fields[3] as String,
      currencySymbol: fields[4] as String,
      note: fields[5] as String,
      category: fields[6] as String,
      date: fields[7] as DateTime,
      syncedToNotion: fields[8] as bool,
      notionPageId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.currencySymbol)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.syncedToNotion)
      ..writeByte(9)
      ..write(obj.notionPageId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
