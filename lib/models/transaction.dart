import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String currency;

  @HiveField(4)
  String currencySymbol;

  @HiveField(5)
  String note;

  @HiveField(6)
  String category;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  bool syncedToNotion;

  @HiveField(9)
  String? notionPageId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.currencySymbol,
    required this.note,
    required this.category,
    required this.date,
    this.syncedToNotion = false,
    this.notionPageId,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'amount': amount,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'note': note,
        'category': category,
        'date': date.toIso8601String(),
        'syncedToNotion': syncedToNotion,
        'notionPageId': notionPageId,
      };
}
