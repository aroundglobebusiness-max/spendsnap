import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class CsvService {
  static Future<void> exportAndShare(List<Transaction> transactions) async {
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Amount', 'Currency', 'Category', 'Note', 'Synced to Notion'],
      ...transactions.map((t) => [
            t.date.toLocal().toString().split('.')[0],
            t.type.toUpperCase(),
            t.amount.toStringAsFixed(2),
            t.currency,
            t.category,
            t.note,
            t.syncedToNotion ? 'Yes' : 'No',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spendsnap_export.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SpendSnap Transactions Export',
    );
  }
}
