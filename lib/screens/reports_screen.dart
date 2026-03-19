import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/storage_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
        title: Text('Reports',
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppTheme.accent)),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'Monthly'), Tab(text: 'By Category')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_MonthlyChart(), _CategoryChart()],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = StorageService.getMonthlyExpenses();
    if (data.isEmpty) return _EmptyState();
    final sorted = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Spending',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.accent)),
          const SizedBox(height: 8),
          Text('Last ${sorted.length} months',
              style: TextStyle(fontSize: 13, color: AppTheme.muted)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(BarChartData(
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${StorageService.defaultSymbol}${rod.toY.toStringAsFixed(0)}',
                    GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= sorted.length) return const SizedBox();
                      final parts = sorted[idx].key.split('-');
                      final month = DateFormat('MMM').format(
                          DateTime(int.parse(parts[0]), int.parse(parts[1])));
                      return Text(month,
                          style: TextStyle(fontSize: 11, color: AppTheme.muted));
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppTheme.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(
                  toY: e.value.value,
                  color: AppTheme.red.withOpacity(0.7),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                )],
              )).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  static const _colors = [
    Color(0xFF8B3A3A), Color(0xFF3A6B4A), Color(0xFF3A4E8B),
    Color(0xFF8B6B3A), Color(0xFF6B3A8B), Color(0xFF3A8B7B),
    Color(0xFF8B7B3A), Color(0xFF4A3A8B),
  ];

  @override
  Widget build(BuildContext context) {
    final data = StorageService.getCategoryBreakdown();
    if (data.isEmpty) return _EmptyState();
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppTheme.accent)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: sorted.asMap().entries.map((e) {
                final pct = (e.value.value / total * 100);
                return PieChartSectionData(
                  value: e.value.value,
                  color: _colors[e.key % _colors.length],
                  radius: 60,
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: Colors.white),
                );
              }).toList(),
            )),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = sorted[i];
                final pct = e.value / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: _colors[i % _colors.length],
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.key,
                          style: const TextStyle(fontSize: 14, color: AppTheme.accent))),
                      Text('${StorageService.defaultSymbol}${e.value.toStringAsFixed(0)}',
                          style: GoogleFonts.dmSerifDisplay(fontSize: 15, color: AppTheme.accent)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text('${pct.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Add transactions to see reports',
              style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}
