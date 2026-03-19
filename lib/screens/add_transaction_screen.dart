import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:gap/gap.dart';
import '../theme.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/notion_service.dart';

const _expenseCats = [
  '🛵 Petrol', '🍽 Food', '🛒 Shopping', '🚌 Transport',
  '💊 Health', '🏠 Rent', '📱 Bills', '🎮 Entertainment',
  '💸 Transfer', '📦 Other',
];

const _incomeCats = [
  '💼 Salary', '🧑‍💻 Freelance', '📈 Investment',
  '🎁 Gift', '💰 Refund', '📦 Other',
];

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'expense';
  String _currency = StorageService.defaultCurrency;
  String _symbol = StorageService.defaultSymbol;
  String _selectedCat = '';
  bool _saving = false;

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<String> get _cats => _type == 'expense' ? _expenseCats : _incomeCats;

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (_selectedCat.isEmpty) {
      _showSnack('Pick a category');
      return;
    }
    setState(() => _saving = true);
    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      amount: amount,
      currency: _currency,
      currencySymbol: _symbol,
      note: _noteCtrl.text.trim().isEmpty
          ? _selectedCat.replaceAll(RegExp(r'[^\w\s]'), '').trim()
          : _noteCtrl.text.trim(),
      category: _selectedCat,
      date: DateTime.now(),
    );
    await StorageService.add(txn);
    if (NotionService.isConfigured) {
      final pageId = await NotionService.syncTransaction(txn);
      if (pageId != null) {
        txn.syncedToNotion = true;
        txn.notionPageId = pageId;
        await StorageService.update(txn);
      }
    }
    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0CEC8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Log Transaction',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: AppTheme.accent)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _TypeBtn(label: '↓ Expense', active: _type == 'expense', activeColor: AppTheme.red,
                              onTap: () => setState(() { _type = 'expense'; _selectedCat = ''; })),
                          _TypeBtn(label: '↑ Income', active: _type == 'income', activeColor: AppTheme.green,
                              onTap: () => setState(() { _type = 'income'; _selectedCat = ''; })),
                        ],
                      ),
                    ),
                    const Gap(16),
                    Container(
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => showCurrencyPicker(
                              context: context,
                              onSelect: (c) => setState(() { _currency = c.code; _symbol = c.symbol; }),
                            ),
                            child: Text(_symbol,
                                style: GoogleFonts.dmSerifDisplay(fontSize: 30, color: AppTheme.muted)),
                          ),
                          const Gap(8),
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: true,
                              style: GoogleFonts.dmSerifDisplay(fontSize: 42, color: AppTheme.accent),
                              decoration: const InputDecoration(
                                border: InputBorder.none, filled: false,
                                hintText: '0',
                                hintStyle: TextStyle(color: Color(0xFFCCC9C0)),
                              ),
                            ),
                          ),
                          Text(_currency, style: TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        filled: true, fillColor: AppTheme.surface,
                      ),
                    ),
                    const Gap(16),
                    Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted, letterSpacing: 0.5)),
                    const Gap(8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _cats.map((cat) {
                        final selected = _selectedCat == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCat = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.accent : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppTheme.accent : AppTheme.border),
                            ),
                            child: Text(cat, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppTheme.muted, fontWeight: FontWeight.w500)),
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save →', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.active, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)] : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: active ? activeColor : AppTheme.muted)),
        ),
      ),
    );
  }
}
