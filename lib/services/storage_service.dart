import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class StorageService {
  static const _boxName = 'transactions';
  static const _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter());
    await Hive.openBox<Transaction>(_boxName);
    await Hive.openBox(_settingsBox);
  }

  static Box<Transaction> get _box => Hive.box<Transaction>(_boxName);
  static Box get _settings => Hive.box(_settingsBox);

  static List<Transaction> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> add(Transaction txn) async {
    await _box.put(txn.id, txn);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static Future<void> update(Transaction txn) async {
    await _box.put(txn.id, txn);
  }

  static double getTotalIncome() {
    return _box.values
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getTotalExpense() {
    return _box.values
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getBalance() => getTotalIncome() - getTotalExpense();

  static Map<String, double> getMonthlyExpenses() {
    final Map<String, double> result = {};
    for (final t in _box.values.where((t) => t.isExpense)) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + t.amount;
    }
    return result;
  }

  static Map<String, double> getCategoryBreakdown() {
    final Map<String, double> result = {};
    for (final t in _box.values.where((t) => t.isExpense)) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }

  static String get notionToken =>
      _settings.get('notionToken', defaultValue: '');
  static String get notionDbId =>
      _settings.get('notionDbId', defaultValue: '');
  static String get defaultCurrency =>
      _settings.get('defaultCurrency', defaultValue: 'INR');
  static String get defaultSymbol =>
      _settings.get('defaultSymbol', defaultValue: '₹');

  static Future<void> saveNotionSettings(String token, String dbId) async {
    await _settings.put('notionToken', token);
    await _settings.put('notionDbId', dbId);
  }

  static Future<void> saveDefaultCurrency(String code, String symbol) async {
    await _settings.put('defaultCurrency', code);
    await _settings.put('defaultSymbol', symbol);
  }
}
