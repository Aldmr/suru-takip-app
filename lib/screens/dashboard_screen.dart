import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../widgets/bottom_nav.dart';
import 'reports_screen.dart';
import 'backup_screen.dart';
import '../services/user_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const DashboardScreen({
    super.key,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _stats = {'total': 0, 'pregnant': 0, 'sick': 0, 'vaccineNeeded': 0};
  List<AlertItem> _alerts = [];

  @override
  void initState() {
    super.initState();
    FarmManager.instance.addListener(_onFarmChanged);
    _loadStats();
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
      _alerts = [];
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    final farmId = FarmManager.instance.activeFarmId;
    try {
      final stats = await DatabaseHelper.instance.getSheepStats(farmId: farmId);
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {}

    try {
      final alerts = await DatabaseHelper.instance.getUpcomingAlerts(farmId: farmId);
      if (!mounted) return;
      setState(() => _alerts = alerts);
    } catch (_) {}
  }

  Future<void> _showFarmSwitcher() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final farms = FarmManager.instance.farms;
          final activeFarmId = FarmManager.instance.activeFarmId;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.wool,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Çiftlik Seç',
                  style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 20, color: AppColors.soil),
                ),
                const SizedBox(height: 12),
                ...farms.map((farm) {
                  final isActive = farm.id == activeFarmId;
                  return GestureDetector(
                    onTap: () {
                      FarmManager.instance.switchFarm(farm);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.soil.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isActive ? Border.all(color: AppColors.soil, width: 1.5) : null,
                        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil),
                                ),
                                if (farm.location != null)
                                  Text(
                                    farm.location!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                                  ),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(Icons.check_circle_rounded, color: AppColors.soil, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    await _showAddFarmDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.mist, width: 1),
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: AppColors.sage),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Yeni Çiftlik Ekle',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.bark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddFarmDialog() async {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.wool,
        title: const Text(
          'Yeni Çiftlik',
          style: TextStyle(fontFamily: 'DMSerifDisplay', color: AppColors.soil),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Çiftlik adı',
                hintText: 'Ahmet Bey Çiftliği',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Konum (opsiyonel)',
                hintText: 'Konya',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.soil,
              foregroundColor: AppColors.straw,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    // nameCtrl/locationCtrl: local vars, GC handles cleanup (no dispose needed)
    if (ok == true && mounted) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;
      final location = locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim();
      final farm = await FarmManager.instance.createFarm(name, location: location);
      FarmManager.instance.switchFarm(farm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmName = FarmManager.instance.activeFarm?.name ?? '—';
    final userName = UserPreferences.instance.userName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'GÜNAYDIN' : hour < 18 ? 'İYİ GÜNLER' : 'İYİ AKŞAMLAR';
    final greetingLine = userName.isNotEmpty ? '$greeting, ${userName.toUpperCase()}' : greeting;
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          _DashboardHeader(
            stats: _stats,
            farmName: farmName,
            greeting: greetingLine,
            onFarmTap: _showFarmSwitcher,
            onAccountTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                      child: Text(
                        '⚡ BUGÜNÜN GÖREVLERİ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bark,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (_alerts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Row(
                            children: [
                              Text('✅', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 10),
                              Text('Her şey yolunda!', style: TextStyle(fontSize: 12, color: AppColors.soil, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._alerts.map((a) => _AlertCard(alert: a)),
                    const SizedBox(height: 8),
                    _NfcQuickButton(onTap: () => widget.onNavTap(2)),
                    const SizedBox(height: 8),
                    _ReportsButton(onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReportsScreen(
                        navIndex: widget.navIndex,
                        onNavTap: widget.onNavTap,
                      )),
                    )),
                    const SizedBox(height: 20),
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
}

// ── Header with stats ────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final Map<String, int> stats;
  final String farmName;
  final String greeting;
  final VoidCallback onFarmTap;
  final VoidCallback onAccountTap;

  const _DashboardHeader({
    required this.stats,
    required this.farmName,
    required this.greeting,
    required this.onFarmTap,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x33E8C97A), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 8,
              child: SafeArea(
                bottom: false,
                child: IconButton(
                  icon: const Icon(Icons.account_circle_outlined, color: AppColors.straw, size: 26),
                  tooltip: 'Hesap & Yedekleme',
                  onPressed: onAccountTap,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onFarmTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          farmName,
                          style: const TextStyle(
                            fontFamily: 'DMSerifDisplay',
                            fontSize: 22,
                            color: AppColors.straw,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.unfold_more_rounded, color: AppColors.mutedText, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatBox(value: '${stats['total']}', label: 'Toplam Koyun')),
                      const SizedBox(width: 8),
                      Expanded(child: _StatBox(value: '${stats['pregnant']}', label: 'Gebe')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatBox(value: '${stats['sick']}', label: 'Hasta')),
                      const SizedBox(width: 8),
                      Expanded(child: _StatBox(value: '${stats['vaccineNeeded']}', label: 'Aşı Bekleyen')),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              fontSize: 26,
              color: AppColors.straw,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert card ───────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertItem alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final borderColor = alert.isGreen ? AppColors.sage : AppColors.rust;
    final dotBg = alert.isGreen
        ? AppColors.sage.withValues(alpha: 0.15)
        : AppColors.rust.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
              child: Center(
                child: Text(alert.icon, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.soil,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    alert.subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reports button ────────────────────────────────────────────────────────────
class _ReportsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raporlar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil),
                ),
                SizedBox(height: 1),
                Text(
                  'Sürü istatistikleri ve özet',
                  style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

// ── NFC quick button ──────────────────────────────────────────────────────────
class _NfcQuickButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NfcQuickButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.soil,
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AE8C97A), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.straw,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📡', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Küpe Tara',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Etikete yaklaştır',
                  style: TextStyle(fontSize: 10, color: AppColors.mutedText),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
