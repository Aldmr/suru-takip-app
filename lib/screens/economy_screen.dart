import 'dart:io';
import '../widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';
import 'all_transactions_screen.dart';

class EconomyScreen extends StatefulWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const EconomyScreen({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  String _period = 'month';
  Map<String, double> _summary = {'income': 0, 'expense': 0, 'net': 0};
  List<FinancialTransaction> _recent = [];
  List<Map<String, dynamic>> _trend = [];
  Map<String, double> _breakdown = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    FarmManager.instance.addListener(_onFarmChanged);
    _load();
  }

  @override
  void dispose() {
    FarmManager.instance.removeListener(_onFarmChanged);
    super.dispose();
  }

  void _onFarmChanged() {
    if (!mounted) return;
    setState(() {
      _summary = {'income': 0, 'expense': 0, 'net': 0};
      _recent = [];
      _trend = [];
      _breakdown = {};
      _loaded = false;
    });
    _load();
  }

  Future<void> _load() async {
    final farmId = FarmManager.instance.activeFarmId;
    try {
      final s = await DatabaseHelper.instance.getFinancialSummary(period: _period, farmId: farmId);
      if (mounted) setState(() => _summary = s);
    } catch (_) {}
    try {
      final r = await DatabaseHelper.instance.getRecentTransactions(farmId: farmId, limit: 5);
      if (mounted) setState(() => _recent = r);
    } catch (_) {}
    try {
      final t = await DatabaseHelper.instance.getMonthlyTrend(farmId: farmId, months: 6);
      if (mounted) setState(() => _trend = t);
    } catch (_) {}
    try {
      final b = await DatabaseHelper.instance.getExpenseBreakdown(period: _period, farmId: farmId);
      if (mounted) setState(() { _breakdown = b; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final all = await DatabaseHelper.instance.getAllTransactions(
          period: _period, farmId: FarmManager.instance.activeFarmId);
      final sb = StringBuffer();
      sb.writeln('Tarih,Tür,Kategori,Tutar,Alıcı/Not');
      for (final t in all) {
        final d = '${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}';
        final type = t.type == 'income' ? 'Gelir' : 'Gider';
        final cat = _categoryLabel(t.category);
        sb.writeln('"$d","$type","$cat","${t.amount}","${t.buyerName ?? t.note ?? ""}"');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ekonomi_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(sb.toString(), flush: true);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: 'SürüTakip — Ekonomi Raporu');
    } catch (e) {
      if (mounted) {
        showAppNotification(context, 'Dışa aktarma hatası: $e', isError: true);
      }
    }
  }

  void _changePeriod(String p) {
    setState(() { _period = p; _loaded = false; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final net = _summary['net'] ?? 0;
    final isProfit = net >= 0;
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          _Header(
            period: _period,
            summary: _summary,
            isProfit: isProfit,
            onPeriodChanged: _changePeriod,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActionRow(
                      onIncome: () async {
                        final ok = await Navigator.push<bool>(
                            context, MaterialPageRoute(builder: (_) => const AddIncomeScreen()));
                        if (ok == true) { setState(() => _loaded = false); _load(); }
                      },
                      onExpense: () async {
                        final ok = await Navigator.push<bool>(
                            context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
                        if (ok == true) { setState(() => _loaded = false); _load(); }
                      },
                    ),
                    const SizedBox(height: 14),
                    _sectionRow('Son İşlemler', 'Tümünü Gör', onAction: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen()));
                    }),
                    const SizedBox(height: 8),
                    if (!_loaded)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.soil),
                      ))
                    else if (_recent.isEmpty)
                      _emptyCard('Henüz işlem yok')
                    else
                      ..._recent.map((t) => _TransactionTile(transaction: t)),
                    const SizedBox(height: 16),
                    if (_trend.isNotEmpty) ...[
                      _sectionRow('Aylık Trend', null),
                      const SizedBox(height: 8),
                      _TrendChart(trend: _trend),
                      const SizedBox(height: 16),
                    ],
                    if (_breakdown.isNotEmpty) ...[
                      _sectionRow('Gider Dağılımı', null),
                      const SizedBox(height: 8),
                      _BreakdownCard(breakdown: _breakdown),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _exportCsv,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x0F000000)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📥', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Text('Tablo Olarak Dışa Aktar',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.bark)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppBottomNav(currentIndex: widget.navIndex, onTap: widget.onNavTap),
        ],
      ),
    );
  }

  Widget _sectionRow(String title, String? action, {VoidCallback? onAction}) => Row(
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.bark, letterSpacing: 0.8)),
          if (action != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onAction,
              child: Text(action,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
            ),
          ]
        ],
      );

  Widget _emptyCard(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))]),
        child: Center(
            child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
      );
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String period;
  final Map<String, double> summary;
  final bool isProfit;
  final ValueChanged<String> onPeriodChanged;

  const _Header({
    required this.period,
    required this.summary,
    required this.isProfit,
    required this.onPeriodChanged,
  });

  String _fmt(double v) {
    if (v >= 1000) return '₺${(v / 1000).toStringAsFixed(1)}B';
    return '₺${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final net = summary['net'] ?? 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('DÖNEM',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.mutedText, letterSpacing: 0.8)),
                  const Spacer(),
                  _PeriodTab(label: 'Bu Ay', value: 'month', current: period, onTap: onPeriodChanged),
                  const SizedBox(width: 4),
                  _PeriodTab(label: 'Bu Yıl', value: 'year', current: period, onTap: onPeriodChanged),
                  const SizedBox(width: 4),
                  _PeriodTab(label: 'Tümü', value: 'all', current: period, onTap: onPeriodChanged),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Net Kâr',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.mutedText,
                      fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${net < 0 ? "-" : "+"}₺${net.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontFamily: 'DMSerifDisplay', fontSize: 32, color: AppColors.straw, height: 1.1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isProfit
                          ? AppColors.sage.withValues(alpha: 0.2)
                          : AppColors.rust.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isProfit ? '▲ KÂR' : '▼ ZARAR',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isProfit ? AppColors.sage : AppColors.rust,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniCard(
                      icon: '📈',
                      value: _fmt(summary['income'] ?? 0),
                      label: 'Toplam Gelir',
                      valueColor: AppColors.sage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniCard(
                      icon: '📉',
                      value: _fmt(summary['expense'] ?? 0),
                      label: 'Toplam Gider',
                      valueColor: const Color(0xFFE8826A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label, value, current;
  final ValueChanged<String> onTap;

  const _PeriodTab(
      {required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.straw : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.soil : AppColors.mutedText,
                letterSpacing: 0.3)),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String icon, value, label;
  final Color valueColor;

  const _MiniCard(
      {required this.icon, required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontFamily: 'DMSerifDisplay', fontSize: 18, color: valueColor, height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Transaction tile ───────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final icon = _categoryIcon(transaction.category);
    final d = transaction.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final label = _categoryLabel(transaction.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.sage.withValues(alpha: 0.15)
                  : AppColors.rust.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.buyerName != null
                      ? '${transaction.buyerName} — $label'
                      : label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.soil),
                ),
                Text('$dateStr · $label',
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : "-"}₺${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 15,
                color: isIncome ? AppColors.sage : AppColors.rust),
          ),
        ],
      ),
    );
  }
}

// ── Trend chart ────────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trend;

  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxVal = trend.fold<double>(0, (m, r) {
      final inc = (r['income'] as double);
      final exp = (r['expense'] as double);
      return [m, inc, exp].reduce((a, b) => a > b ? a : b);
    });
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legend(AppColors.sage, 'Gelir'),
              const SizedBox(width: 12),
              _legend(AppColors.rust.withValues(alpha: 0.45), 'Gider'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((r) {
                final inc = r['income'] as double;
                final exp = r['expense'] as double;
                final monthStr = r['month'] as String;
                final monthIdx = int.tryParse(monthStr.split('-').last) ?? 1;
                final label = months[monthIdx - 1];
                final incH = maxVal > 0 ? (inc / maxVal * 54).clamp(2.0, 54.0) : 2.0;
                final expH = maxVal > 0 ? (exp / maxVal * 54).clamp(0.0, 54.0) : 0.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 8, height: incH,
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 8, height: expH,
                            decoration: BoxDecoration(
                              color: AppColors.rust.withValues(alpha: 0.45),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.mutedText)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
        ],
      );
}

// ── Expense breakdown ──────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final Map<String, double> breakdown;

  const _BreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final colors = [AppColors.bark, AppColors.rust, AppColors.sky, AppColors.sage, AppColors.soil, AppColors.mutedText];
    final entries = breakdown.entries.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final fraction = total > 0 ? (entries[i].value / total).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    '${_categoryIcon(entries[i].key)} ${_categoryLabel(entries[i].key)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.soil, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 6, color: AppColors.mist),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Text(
                    '₺${entries[i].value.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.soil),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Action row ─────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final VoidCallback onIncome;
  final VoidCallback onExpense;

  const _ActionRow({required this.onIncome, required this.onExpense});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onIncome,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.soil,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppColors.straw, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('+', style: TextStyle(fontSize: 18, color: AppColors.soil, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 8),
                  const Text('Gelir Ekle',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onExpense,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.rust.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.rust.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: AppColors.rust.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('📉', style: TextStyle(fontSize: 13))),
                  ),
                  const SizedBox(width: 8),
                  const Text('Gider Ekle',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.rust)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _categoryIcon(String cat) => switch (cat) {
  'animal_sale' => '🐑',
  'wool' => '🧶',
  'milk' => '🥛',
  'feed' => '🌾',
  'vaccine' => '💉',
  'medicine' => '💊',
  'vet' => '🩺',
  'maintenance' => '🔧',
  _ => '📦',
};

String _categoryLabel(String cat) => switch (cat) {
  'animal_sale' => 'Hayvan Satışı',
  'wool' => 'Yapağı / Yün',
  'milk' => 'Süt',
  'feed' => 'Yem',
  'vaccine' => 'Aşı',
  'medicine' => 'İlaç',
  'vet' => 'Veteriner',
  'maintenance' => 'Bakım',
  _ => 'Diğer',
};
