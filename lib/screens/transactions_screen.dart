import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../services/notion_service.dart';
import 'reports_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _transactions = StorageService.getAll());
  }

  double get _totalIncome =>
      _transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _totalExpense =>
      _transactions.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  double get _balance => _totalIncome - _totalExpense;

  String _fmt(double v) =>
      '${StorageService.defaultSymbol}${v.toStringAsFixed(0)}';

  Map<String, List<Transaction>> _grouped() {
    final Map<String, List<Transaction>> groups = {};
    for (final t in _transactions) {
      final key = DateFormat('EEE, MMM d').format(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  Future<void> _syncAll() async {
    if (!NotionService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Set up Notion in Settings first'),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _syncing = true);
    final count = await NotionService.syncAll();
    setState(() { _syncing = false; _load(); });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ Synced $count transactions to Notion'),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF7),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transactions',
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppTheme.accent)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            color: AppTheme.muted,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          IconButton(
            icon: _syncing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            color: AppTheme.muted,
            onPressed: _syncing ? null : _syncAll,
          ),
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            color: AppTheme.muted,
            onPressed: () => CsvService.exportAndShare(_transactions),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                _SumCard(label: 'Income', value: _fmt(_totalIncome), color: AppTheme.green),
                const SizedBox(width: 10),
                _SumCard(label: 'Spent', value: _fmt(_totalExpense), color: AppTheme.red),
                const SizedBox(width: 10),
                _SumCard(label: 'Balance', value: _fmt(_balance.abs()),
                    color: _balance >= 0 ? AppTheme.green : AppTheme.red),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No transactions yet',
                            style: TextStyle(color: AppTheme.muted)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(entry.key,
                                style: TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.muted,
                                    letterSpacing: 0.6)),
                          ),
                          ...entry.value.map((t) => _TxnTile(
                                txn: t,
                                onDelete: () async {
                                  await StorageService.delete(t.id);
                                  _load();
                                },
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SumCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: color),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: AppTheme.muted,
                    fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Transaction txn;
  final VoidCallback onDelete;
  const _TxnTile({required this.txn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final emoji = txn.category.isNotEmpty
        ? txn.category.characters.first
        : (txn.isExpense ? '💸' : '💰');
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 1))),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: txn.isExpense
                    ? AppTheme.red.withOpacity(0.08)
                    : AppTheme.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.note,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w500, color: AppTheme.accent),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${txn.category.replaceAll(RegExp(r'[^\w\s]'), '').trim()} · ${DateFormat('hh:mm a').format(txn.date)}${txn.syncedToNotion ? ' · ✓ Notion' : ''}',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            Text(
              '${txn.isExpense ? '-' : '+'}${txn.currencySymbol}${txn.amount.toStringAsFixed(0)}',
              style: GoogleFonts.dmSerifDisplay(fontSize: 17,
                  color: txn.isExpense ? AppTheme.red : AppTheme.green),
            ),
          ],
        ),
      ),
    );
  }
}
