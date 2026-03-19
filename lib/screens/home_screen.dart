import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/notion_service.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
    _checkUnsynced();
  }

  void _checkUnsynced() {
    setState(() {
      _unsyncedCount =
          StorageService.getAll().where((t) => !t.syncedToNotion).length;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeStr {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateStr {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[_now.weekday - 1]} ${months[_now.month - 1]} ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _BlobBackground()),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 12),
                    child: Stack(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()));
                            _checkUnsynced();
                          },
                          icon: const Icon(Icons.tune_rounded),
                          color: AppTheme.accent.withOpacity(0.6),
                        ),
                        if (_unsyncedCount > 0)
                          Positioned(
                            right: 8, top: 8,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      Text(_dateStr,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            color: AppTheme.accent.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          )),
                      const SizedBox(height: 4),
                      Text(_timeStr,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 108,
                            color: AppTheme.accent.withOpacity(0.12),
                            height: 1.0,
                            letterSpacing: -4,
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickStat(
                          label: 'Balance',
                          value: '${StorageService.defaultSymbol}${StorageService.getBalance().abs().toStringAsFixed(0)}',
                          color: StorageService.getBalance() >= 0 ? AppTheme.green : AppTheme.red,
                        ),
                        Container(width: 1, height: 30, color: AppTheme.border),
                        _QuickStat(
                          label: 'Today',
                          value: _getTodayExpense(),
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LockBtn(
                          icon: Icons.add_rounded,
                          label: 'Add',
                          onTap: () async {
                            await Navigator.push(context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const AddTransactionScreen(),
                                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ));
                            _checkUnsynced();
                            setState(() {});
                          },
                        ),
                        _LockBtn(
                          icon: Icons.format_list_bulleted_rounded,
                          label: 'History',
                          onTap: () async {
                            await Navigator.push(context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const TransactionsScreen(),
                                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ));
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayExpense() {
    final today = DateTime.now();
    final total = StorageService.getAll()
        .where((t) => t.isExpense && t.date.year == today.year && t.date.month == today.month && t.date.day == today.day)
        .fold(0.0, (s, t) => s + t.amount);
    return '${StorageService.defaultSymbol}${total.toStringAsFixed(0)}';
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _LockBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LockBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: AppTheme.accent, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BlobBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(), child: const SizedBox.expand());
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC8C5BC), Color(0xFFA8A59C)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6));
    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.35, size.width, size.height * 0.45);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFD8D5CC), Color(0xFFB5B2A8)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width * 0.7, size.height * 0.5));
    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.65, size.height * 0.58);
    path2.lineTo(size.width * 0.65, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    final paint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF525048), Color(0xFF3A3835)],
      ).createShader(Rect.fromLTWH(size.width * 0.3, size.height * 0.6, size.width * 0.7, size.height * 0.4));
    final path3 = Path();
    path3.moveTo(size.width * 0.35, size.height * 0.7);
    path3.quadraticBezierTo(size.width * 0.6, size.height * 0.6, size.width, size.height * 0.65);
    path3.lineTo(size.width, size.height);
    path3.lineTo(size.width * 0.35, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
