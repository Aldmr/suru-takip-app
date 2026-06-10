import 'dart:io';
import '../widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../widgets/bottom_nav.dart';

class ReportsScreen extends StatefulWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const ReportsScreen({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, int> _stats = {'total': 0, 'pregnant': 0, 'sick': 0, 'vaccineNeeded': 0};
  Map<String, int> _genderCounts = {'female': 0, 'male': 0};
  Map<String, int> _statusDist = {};
  Map<String, int> _breedDist = {};
  bool _loaded = false;
  bool _isExporting = false;

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
      _stats = {'total': 0, 'pregnant': 0, 'sick': 0, 'vaccineNeeded': 0};
      _genderCounts = {'female': 0, 'male': 0};
      _statusDist = {};
      _breedDist = {};
      _loaded = false;
    });
    _load();
  }

  Future<void> _load() async {
    final farmId = FarmManager.instance.activeFarmId;
    try {
      final stats = await DatabaseHelper.instance.getSheepStats(farmId: farmId);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}

    try {
      final gender = await DatabaseHelper.instance.getGenderCounts(farmId: farmId);
      if (mounted) setState(() => _genderCounts = gender);
    } catch (_) {}

    try {
      final status = await DatabaseHelper.instance.getFullStatusDistribution(farmId: farmId);
      if (mounted) setState(() => _statusDist = status);
    } catch (_) {}

    try {
      final breed = await DatabaseHelper.instance.getBreedDistribution(farmId: farmId);
      if (mounted) {
        setState(() {
          _breedDist = breed;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final csv = await DatabaseHelper.instance.buildCsvExport(farmId: FarmManager.instance.activeFarmId);
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/suru_rapor_$ts.csv');
      await file.writeAsString(csv, flush: true);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SürüTakip — Sürü Raporu',
      );
    } catch (e) {
      if (mounted) {
        showAppNotification(context, 'Dışa aktarma hatası: $e', isError: true);
      }
    }
    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final total = _stats['total'] ?? 0;
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          _ReportsHeader(stats: _stats, genderCounts: _genderCounts),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                child: !_loaded
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: AppColors.soil)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Sürü Durumu'),
                          const SizedBox(height: 8),
                          _StatusCard(statusDist: _statusDist, total: total),
                          const SizedBox(height: 16),
                          _sectionTitle('Irk Dağılımı'),
                          const SizedBox(height: 8),
                          _BreedCard(breedDist: _breedDist),
                          const SizedBox(height: 20),
                          _ExportButton(isExporting: _isExporting, onTap: _exportCsv),
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

  Widget _sectionTitle(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.bark,
      letterSpacing: 0.8,
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _ReportsHeader extends StatelessWidget {
  final Map<String, int> stats;
  final Map<String, int> genderCounts;

  const _ReportsHeader({required this.stats, required this.genderCounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GENEL BAKIŞ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedText, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              const Text(
                'Raporlar',
                style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 22, color: AppColors.straw),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatBox(value: '${stats['total']}', label: 'Aktif Koyun')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(value: '${genderCounts['female']}', label: 'Dişi')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(value: '${genderCounts['male']}', label: 'Erkek')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DMSerifDisplay',
              fontSize: 22,
              color: AppColors.straw,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mutedText, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Status distribution card ──────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final Map<String, int> statusDist;
  final int total;

  const _StatusCard({required this.statusDist, required this.total});

  static const _statusInfo = {
    'active': ('Sağlıklı', AppColors.sage),
    'pregnant': ('Gebe', AppColors.sky),
    'sick': ('Hasta', AppColors.rust),
    'sold': ('Satıldı', AppColors.mutedText),
    'dead': ('Vefat', AppColors.bark),
  };

  @override
  Widget build(BuildContext context) {
    final grandTotal = statusDist.values.fold(0, (a, b) => a + b);
    return _Card(
      child: Column(
        children: _statusInfo.entries.map((e) {
          final count = statusDist[e.key] ?? 0;
          final (label, color) = e.value;
          return _DistBar(
            label: label,
            count: count,
            total: grandTotal,
            color: color,
          );
        }).toList(),
      ),
    );
  }
}

// ── Breed distribution card ───────────────────────────────────────────────────
class _BreedCard extends StatelessWidget {
  final Map<String, int> breedDist;

  const _BreedCard({required this.breedDist});

  @override
  Widget build(BuildContext context) {
    if (breedDist.isEmpty) {
      return _Card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('Kayıt yok', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ),
        ),
      );
    }
    final total = breedDist.values.fold(0, (a, b) => a + b);
    final colors = [AppColors.soil, AppColors.sage, AppColors.sky, AppColors.rust, AppColors.straw];
    final entries = breedDist.entries.toList();
    return _Card(
      child: Column(
        children: List.generate(entries.length, (i) {
          return _DistBar(
            label: entries[i].key,
            count: entries[i].value,
            total: total,
            color: colors[i % colors.length],
          );
        }),
      ),
    );
  }
}

// ── Export button ─────────────────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onTap;

  const _ExportButton({required this.isExporting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExporting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.soil,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isExporting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.straw),
              )
            else
              const Text('📤', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              isExporting ? 'Hazırlanıyor...' : 'Tablo Olarak Dışa Aktar',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.straw,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _DistBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = (total == 0 || count == 0) ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.bark, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: AppColors.mist),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: AppColors.soil, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
