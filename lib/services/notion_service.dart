import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import 'storage_service.dart';

class NotionService {
  static const _baseUrl = 'https://api.notion.com/v1';
  static const _version = '2022-06-28';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${StorageService.notionToken}',
        'Content-Type': 'application/json',
        'Notion-Version': _version,
      };

  static bool get isConfigured =>
      StorageService.notionToken.isNotEmpty &&
      StorageService.notionDbId.isNotEmpty;

  static Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/databases/${StorageService.notionDbId}'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> syncTransaction(Transaction txn) async {
    if (!isConfigured) return null;
    try {
      final body = {
        'parent': {'database_id': StorageService.notionDbId},
        'properties': {
          'Name': {
            'title': [
              {'text': {'content': txn.note}}
            ]
          },
          'Amount': {'number': txn.amount},
          'Type': {
            'select': {'name': txn.isExpense ? 'Expense' : 'Income'},
          },
          'Category': {
            'select': {'name': txn.category},
          },
          'Currency': {
            'rich_text': [
              {'text': {'content': txn.currency}}
            ]
          },
          'Date': {
            'date': {'start': txn.date.toIso8601String()},
          },
        },
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/pages'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<int> syncAll() async {
    if (!isConfigured) return 0;
    int count = 0;
    final unsyncedList =
        StorageService.getAll().where((t) => !t.syncedToNotion).toList();
    for (final txn in unsyncedList) {
      final pageId = await syncTransaction(txn);
      if (pageId != null) {
        txn.syncedToNotion = true;
        txn.notionPageId = pageId;
        await StorageService.update(txn);
        count++;
      }
    }
    return count;
  }
}
