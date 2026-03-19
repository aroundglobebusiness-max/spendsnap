import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:gap/gap.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/notion_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenCtrl = TextEditingController();
  final _dbIdCtrl = TextEditingController();
  bool _testing = false;
  bool? _connected;

  @override
  void initState() {
    super.initState();
    _tokenCtrl.text = StorageService.notionToken;
    _dbIdCtrl.text = StorageService.notionDbId;
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _dbIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNotion() async {
    await StorageService.saveNotionSettings(
        _tokenCtrl.text.trim(), _dbIdCtrl.text.trim());
    setState(() => _testing = true);
    final ok = await NotionService.testConnection();
    setState(() { _testing = false; _connected = ok; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✓ Connected to Notion!' : '✗ Check your token & DB ID.'),
        backgroundColor: ok ? AppTheme.green : AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF7),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppTheme.accent)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionHeader('Default Currency'),
          const Gap(8),
          GestureDetector(
            onTap: () => showCurrencyPicker(
              context: context,
              onSelect: (c) async {
                await StorageService.saveDefaultCurrency(c.code, c.symbol);
                setState(() {});
              },
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text(StorageService.defaultSymbol,
                      style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: AppTheme.accent)),
                  const Gap(12),
                  Expanded(child: Text(StorageService.defaultCurrency,
                      style: const TextStyle(fontSize: 16, color: AppTheme.accent))),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
                ],
              ),
            ),
          ),
          const Gap(32),
          _SectionHeader('Notion Sync'),
          const Gap(4),
          Text('Connect to your Notion database to auto-sync every transaction.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted)),
          const Gap(12),
          _InputTile(label: 'Notion Integration Token', hint: 'secret_xxxx...', controller: _tokenCtrl, obscure: true),
          const Gap(8),
          _InputTile(label: 'Database ID', hint: 'Copy from your Notion DB URL', controller: _dbIdCtrl),
          const Gap(16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _testing ? null : _saveNotion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _testing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_connected != null) ...[
                          Icon(_connected! ? Icons.check_circle_outline : Icons.error_outline, size: 16),
                          const Gap(6),
                        ],
                        const Text('Save & Test Connection',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to get your Notion token',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                const Gap(8),
                _Step('1', 'Go to notion.so/my-integrations → Create integration → Copy token'),
                _Step('2', 'Open your Notion database → Share → Connect your integration'),
                _Step('3', 'Copy the database ID from the URL (32-char string)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppTheme.muted, letterSpacing: 0.8));
  }
}

class _InputTile extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  const _InputTile({required this.label, required this.hint, required this.controller, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
        const Gap(4),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true, fillColor: AppTheme.surface,
            hintStyle: TextStyle(color: AppTheme.muted.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step(this.num, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(num,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accent))),
          ),
          const Gap(8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppTheme.muted))),
        ],
      ),
    );
  }
}
