import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../theme/app_theme.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _period = 'all';
  List<FinancialTransaction> _transactions = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loaded = false);
    final list = await DatabaseHelper.instance.getAllTransactions(
      period: _period,
      farmId: FarmManager.instance.activeFarmId,
    );
    if (!mounted) return;
    setState(() {
      _transactions = list;
      _loaded = true;
    });
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loaded && _transactions.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: _loaded ? _transactions.length : 1,
                      itemBuilder: (_, i) {
                        if (!_loaded) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: AppColors.soil),
                            ),
                          );
                        }
                        return _TransactionTile(transaction: _transactions[i]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final net = _totalIncome - _totalExpense;
    final isProfit = net >= 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.straw, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Tüm İşlemler',
                        style: TextStyle(
                            fontFamily: 'DMSerifDisplay',
                            fontSize: 20,
                            color: AppColors.straw)),
                  ),
                  ...[
                    ('Bu Ay', 'month'),
                    ('Bu Yıl', 'year'),
                    ('Tümü', 'all'),
                  ].map((p) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () { setState(() => _period = p.$2); _load(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _period == p.$2 ? AppColors.straw : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p.$1,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _period == p.$2 ? AppColors.soil : AppColors.mutedText,
                                letterSpacing: 0.3)),
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _MiniStat(
                    icon: '📈', label: 'Gelir', amount: _totalIncome, color: AppColors.sage)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(
                    icon: '📉', label: 'Gider', amount: _totalExpense,
                    color: const Color(0xFFE8826A))),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(
                    icon: isProfit ? '▲' : '▼',
                    label: isProfit ? 'Kâr' : 'Zarar',
                    amount: net.abs(),
                    color: isProfit ? AppColors.sage : AppColors.rust)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 60),
      Center(
        child: Text('Bu dönemde işlem yok',
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  final String icon, label;
  final double amount;
  final Color color;

  const _MiniStat({required this.icon, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            '₺${amount.toStringAsFixed(0)}',
            style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 15, color: color, height: 1),
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final d = transaction.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final icon = _categoryIcon(transaction.category);
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
                Text(dateStr,
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

String _categoryIcon(String cat) => switch (cat) {
  'animal_sale' => '🐑',
  'wool'        => '🧶',
  'milk'        => '🥛',
  'feed'        => '🌾',
  'vaccine'     => '💉',
  'medicine'    => '💊',
  'vet'         => '🩺',
  'maintenance' => '🔧',
  _             => '📦',
};

String _categoryLabel(String cat) => switch (cat) {
  'animal_sale' => 'Hayvan Satışı',
  'wool'        => 'Yapağı / Yün',
  'milk'        => 'Süt',
  'feed'        => 'Yem',
  'vaccine'     => 'Aşı',
  'medicine'    => 'İlaç',
  'vet'         => 'Veteriner',
  'maintenance' => 'Bakım',
  _             => 'Diğer',
};
