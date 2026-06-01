import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../widgets/sheep_picker_sheet.dart';
import 'weight_chart_screen.dart';
import 'add_health_record_screen.dart';
import 'add_breeding_record_screen.dart';
import 'add_note_screen.dart';

class SheepProfileScreen extends StatefulWidget {
  final Sheep sheep;

  const SheepProfileScreen({super.key, required this.sheep});

  @override
  State<SheepProfileScreen> createState() => _SheepProfileScreenState();
}

class _SheepProfileScreenState extends State<SheepProfileScreen> {
  int _tabIndex = 0;
  late final PageController _pageController;
  final _tabs = ['Sağlık', 'Üreme', 'Soy', 'Tartım', 'Notlar'];
  late Sheep _sheep;
  List<HealthRecord> _healthRecords = [];
  bool _healthLoaded = false;
  List<BreedingRecord> _breedingRecords = [];
  bool _breedingLoaded = false;
  LineageData? _lineageData;
  bool _lineageLoaded = false;
  List<SheepNote> _notes = [];
  bool _notesLoaded = false;

  @override
  void initState() {
    super.initState();
    _sheep = widget.sheep;
    _pageController = PageController();
    _loadHealth();
    _loadBreeding();
    _loadLineage();
    _loadNotes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    if (widget.sheep.id == null) return;
    final notes = await DatabaseHelper.instance.getNotesBySheepId(widget.sheep.id!);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _notesLoaded = true;
    });
  }

  Future<void> _reloadSheep() async {
    if (widget.sheep.id == null) return;
    await DatabaseHelper.instance.syncSheepStatuses(farmId: widget.sheep.farmId);
    final updated = await DatabaseHelper.instance.getSheepById(widget.sheep.id!);
    if (!mounted || updated == null) return;
    setState(() => _sheep = updated);
  }

  Future<void> _loadHealth() async {
    if (widget.sheep.id == null) return;
    final records = await DatabaseHelper.instance.getHealthRecordsBySheepId(widget.sheep.id!);
    if (!mounted) return;
    setState(() {
      _healthRecords = records;
      _healthLoaded = true;
    });
    _reloadSheep();
  }

  Future<void> _loadBreeding() async {
    if (widget.sheep.id == null) return;
    final records = await DatabaseHelper.instance.getBreedingRecordsBySheepId(widget.sheep.id!);
    if (!mounted) return;
    setState(() {
      _breedingRecords = records;
      _breedingLoaded = true;
    });
    _reloadSheep();
  }

  Future<void> _loadLineage() async {
    if (widget.sheep.id == null) return;
    final data = await DatabaseHelper.instance.getLineageData(widget.sheep.id!);
    if (!mounted) return;
    setState(() {
      _lineageData = data;
      _lineageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────────────────────────
          _ProfileHero(sheep: _sheep),
          // ── Tab row ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final isActive = e.key == _tabIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      e.key,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: e.key < _tabs.length - 1 ? 4 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.soil : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.straw : AppColors.mutedText,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _tabIndex = i),
              children: [
                _HealthTab(
                  sheep: _sheep,
                  records: _healthRecords,
                  loaded: _healthLoaded,
                  onRecordAdded: _loadHealth,
                ),
                _BreedingTab(
                  sheep: _sheep,
                  records: _breedingRecords,
                  loaded: _breedingLoaded,
                  onRecordAdded: _loadBreeding,
                ),
                _LineageTab(
                  sheep: _sheep,
                  lineageData: _lineageData,
                  loaded: _lineageLoaded,
                  onChanged: _loadLineage,
                ),
                _WeightTab(sheep: _sheep),
                _NotesTab(
                  sheep: _sheep,
                  notes: _notes,
                  loaded: _notesLoaded,
                  onNoteAdded: _loadNotes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile hero ─────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final Sheep sheep;

  const _ProfileHero({required this.sheep});

  @override
  Widget build(BuildContext context) {
    final isSick = sheep.status == 'sick';
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
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x26E8C97A), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geri butonu + durum badge'i
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          '← Sürü Listesi',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6A5040), fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      if (sheep.isPregnant) ...[
                        _StatusPill(label: 'GEBE', color: AppColors.sky),
                        const SizedBox(width: 4),
                      ],
                      _StatusPill(
                        label: isSick ? 'HASTA' : 'SAĞLIKLI',
                        color: isSick ? AppColors.rust : AppColors.sage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.straw.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.straw.withValues(alpha: 0.2)),
                        ),
                        child: const Center(child: Text('🐑', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheep.displayName,
                            style: const TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize: 22,
                              color: AppColors.straw,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${sheep.earTag} · NFC: ${_nfcPreview(sheep.nfcUid)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6A5040), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Satır 1: Ağırlık · Yaş · Cinsiyet
                  Row(
                    children: [
                      Expanded(child: _QuickStat(
                        value: '${sheep.lastWeight?.toStringAsFixed(0) ?? '?'}kg',
                        label: 'AĞIRLIK',
                      )),
                      const SizedBox(width: 6),
                      Expanded(child: _QuickStat(
                        value: sheep.ageDetail,
                        label: 'YAŞ',
                      )),
                      const SizedBox(width: 6),
                      Expanded(child: _QuickStat(
                        value: sheep.gender == 'female' ? 'Dişi' : 'Erkek',
                        label: 'CİNSİYET',
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Satır 2: Irk · Doğum (· Grup)
                  Row(
                    children: [
                      Expanded(child: _QuickStat(value: sheep.breed, label: 'IRK')),
                      if (sheep.birthDate != null) ...[
                        const SizedBox(width: 6),
                        Expanded(child: _QuickStat(value: _fmtDate(sheep.birthDate!), label: 'DOĞUM')),
                      ],
                      if (sheep.groupName != null) ...[
                        const SizedBox(width: 6),
                        Expanded(child: _QuickStat(value: sheep.groupName!, label: 'GRUP')),
                      ],
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

String _fmtDate(DateTime d) {
  const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  return '${d.day} ${m[d.month]} ${d.year}';
}

String _nfcPreview(String uid) {
  if (uid.isEmpty) return '—';
  if (uid.length <= 11) return uid;
  return '${uid.substring(0, 11)}...';
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;

  const _QuickStat({required this.value, required this.label});

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
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DMSerifDisplay',
              fontSize: 17,
              color: AppColors.straw,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6A5040),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health tab ────────────────────────────────────────────────────────────────
class _HealthTab extends StatefulWidget {
  final Sheep sheep;
  final List<HealthRecord> records;
  final bool loaded;
  final VoidCallback onRecordAdded;

  const _HealthTab({
    required this.sheep,
    required this.records,
    required this.loaded,
    required this.onRecordAdded,
  });

  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  late List<HealthRecord> _records;
  late bool _loaded;

  @override
  void initState() {
    super.initState();
    _records = widget.records;
    _loaded = widget.loaded;
  }

  @override
  void didUpdateWidget(_HealthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _records = widget.records;
    _loaded = widget.loaded;
  }

  Future<void> _resolve(HealthRecord r) async {
    final now = DateTime.now();
    setState(() {
      _records = [
        for (final rec in _records)
          if (rec.id == r.id)
            HealthRecord(
              id: rec.id,
              sheepId: rec.sheepId,
              type: rec.type,
              name: rec.name,
              date: rec.date,
              nextDate: rec.nextDate ?? now,
              vetName: rec.vetName,
              notes: rec.notes,
              status: 'done',
            )
          else
            rec,
      ];
    });
    await DatabaseHelper.instance.resolveHealthRecord(r.id!, widget.sheep.id!);
    if (mounted) widget.onRecordAdded();
  }

  String _fmt(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _dateStr(HealthRecord r) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final d = r.date;
    final base = '${d.day} ${months[d.month]} ${d.year}';
    switch (r.status) {
      case 'done': return '$base ✓';
      case 'pending': return '$base ⏰';
      case 'late': return '$base !';
      default: return base;
    }
  }

  Color _dotColor(HealthRecord r) {
    switch (r.status) {
      case 'done': return AppColors.sage;
      case 'late': return AppColors.rust;
      default: return AppColors.straw;
    }
  }

  (String, Color) _typeInfo(HealthRecord r) => switch (r.type) {
    'vaccine'  => ('💉 Aşı',      AppColors.sky),
    'disease'  => ('🤒 Hastalık', AppColors.rust),
    'medicine' => ('💊 İlaç',     AppColors.sage),
    'exam'     => ('🩺 Muayene',  AppColors.bark),
    _          => ('📋 Diğer',    AppColors.mutedText),
  };

  @override
  Widget build(BuildContext context) {
    final sheep = widget.sheep;
    return Column(
      children: [
        Expanded(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                  child: _records.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('Henüz sağlık kaydı yok', style: TextStyle(color: AppColors.mutedText)),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAĞLIK GEÇMİŞİ',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 10),
                              ..._records.asMap().entries.map((e) {
                                final r = e.value;
                                final isLast = e.key == _records.length - 1;
                                final isPendingDisease = r.type == 'disease' && r.status == 'pending';
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 7),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColor(r)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(r.name, style: const TextStyle(fontSize: 11.5, color: AppColors.soil, fontWeight: FontWeight.w500)),
                                                const SizedBox(height: 3),
                                                Builder(builder: (_) {
                                                  final (label, color) = _typeInfo(r);
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(alpha: 0.10),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(label,
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isPendingDisease)
                                            GestureDetector(
                                              onTap: () => _resolve(r),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.sage.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
                                                ),
                                                child: const Text('✓ İyileşti',
                                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.sage)),
                                              ),
                                            )
                                          else if (r.type != 'disease')
                                            Text(_dateStr(r), style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                        ],
                                      ),
                                    ),
                                    if (r.type == 'disease')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 18, bottom: 6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              const Text('Başlangıç: ', style: TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                              Text(_fmt(r.date), style: const TextStyle(fontSize: 10, color: AppColors.soil, fontWeight: FontWeight.w500)),
                                            ]),
                                            const SizedBox(height: 2),
                                            Row(children: [
                                              const Text('Bitiş: ', style: TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                              Text(
                                                r.nextDate != null ? _fmt(r.nextDate!) : 'Devam ediyor',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: r.nextDate != null ? AppColors.soil : AppColors.rust,
                                                ),
                                              ),
                                            ]),
                                            if (r.notes != null && r.notes!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(r.notes!, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    if (!isLast) Divider(color: Colors.black.withValues(alpha: 0.04), height: 1),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: GestureDetector(
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddHealthRecordScreen(
                    sheepId: sheep.id!,
                    sheepName: sheep.displayName,
                    earTag: sheep.earTag,
                  ),
                ),
              );
              if (added == true) widget.onRecordAdded();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.soil,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.soil.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Text(
                '+ Kayıt Ekle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.straw),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Breeding tab ──────────────────────────────────────────────────────────────
class _BreedingTab extends StatelessWidget {
  final Sheep sheep;
  final List<BreedingRecord> records;
  final bool loaded;
  final VoidCallback onRecordAdded;

  const _BreedingTab({
    required this.sheep,
    required this.records,
    required this.loaded,
    required this.onRecordAdded,
  });

  String _dateStr(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  (String, String, Color) _typeInfo(BreedingRecord r) {
    switch (r.type) {
      case 'pregnancy':
        final exp = r.expectedBirth;
        final sub = exp != null ? 'Tahmini doğum: ${_dateStr(exp)}' : 'Tahmini tarih yok';
        return ('GEBELİK', sub, AppColors.sky);
      case 'birth':
        final count = r.lambCount;
        final sub = count != null ? '$count yavru doğdu' : 'Yavru sayısı belirtilmedi';
        return ('DOĞUM', sub, AppColors.sage);
      default:
        final sub = r.partnerUid != null ? 'Koç: ${r.partnerUid}' : 'Eşleşme kaydı';
        return ('ÇİFTLEŞME', sub, AppColors.bark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalLambs = records.where((r) => r.type == 'birth').fold<int>(0, (s, r) => s + (r.lambCount ?? 0));

    return Column(
      children: [
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                  child: records.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('Henüz üreme kaydı yok', style: TextStyle(color: AppColors.mutedText)),
                          ),
                        )
                      : Column(
                          children: [
                            // Summary card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _BreedStat(value: '$totalLambs', label: 'Toplam Yavru')),
                                  Expanded(child: _BreedStat(
                                    value: '${records.where((r) => r.type == 'birth').length}',
                                    label: 'Doğum',
                                  )),
                                  Expanded(child: _BreedStat(
                                    value: '${records.where((r) => r.type == 'mating').length}',
                                    label: 'Çiftleşme',
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Records list
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ÜREME GEÇMİŞİ',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.8),
                                  ),
                                  const SizedBox(height: 10),
                                  ...records.asMap().entries.map((e) {
                                    final r = e.value;
                                    final isLast = e.key == records.length - 1;
                                    final (typeLabel, subtitle, color) = _typeInfo(r);
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 7),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4)),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.soil, fontWeight: FontWeight.w500)),
                                                    if (r.notes != null)
                                                      Text(r.notes!, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                                  ],
                                                ),
                                              ),
                                              Text(_dateStr(r.date), style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                                            ],
                                          ),
                                        ),
                                        if (!isLast) Divider(color: Colors.black.withValues(alpha: 0.04), height: 1),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: GestureDetector(
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddBreedingRecordScreen(
                    sheepId: sheep.id!,
                    sheepName: sheep.displayName,
                    earTag: sheep.earTag,
                    farmId: sheep.farmId,
                  ),
                ),
              );
              if (added == true) onRecordAdded();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.soil,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.soil.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Text(
                '+ Kayıt Ekle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.straw),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BreedStat extends StatelessWidget {
  final String value;
  final String label;
  const _BreedStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 22, color: AppColors.soil)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Weight tab ────────────────────────────────────────────────────────────────
class _WeightTab extends StatelessWidget {
  final Sheep sheep;

  const _WeightTab({required this.sheep});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WeightChartScreen(sheep: sheep)),
        ),
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📊', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              const Text('Tartım Grafiğini Görüntüle', style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 18, color: AppColors.soil)),
              const SizedBox(height: 6),
              Text('Son ağırlık: ${sheep.lastWeight} kg', style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
      ),
    );
  }
}

// ── Lineage tab ───────────────────────────────────────────────────────────────
class _LineageTab extends StatefulWidget {
  final Sheep sheep;
  final LineageData? lineageData;
  final bool loaded;
  final VoidCallback onChanged;

  const _LineageTab({
    required this.sheep,
    required this.lineageData,
    required this.loaded,
    required this.onChanged,
  });

  @override
  State<_LineageTab> createState() => _LineageTabState();
}

class _LineageTabState extends State<_LineageTab> {
  Future<void> _linkParent(String role) async {
    final gender = role == 'mother' ? 'female' : 'male';
    final picked = await SheepPickerSheet.show(
      context,
      farmId: widget.sheep.farmId,
      genderFilter: gender,
      excludeSheepId: widget.sheep.id,
    );
    if (picked == null || !mounted || picked.id == null) return;

    final conflict = await DatabaseHelper.instance.setSheepParent(
      sheepId: widget.sheep.id!,
      parentId: picked.id!,
      role: role,
    );

    if (conflict == 'circular' && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Döngüsel İlişki'),
          content: Text('${picked.earTag} bu koyunun soyundan geliyor. Aynı zamanda ebeveyn olarak eklenemez.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
      return;
    }

    if (conflict != null && mounted) {
      final roleLabel = role == 'mother' ? 'annesi' : 'babası';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(role == 'mother' ? 'Anne Değiştir' : 'Baba Değiştir'),
          content: Text('Bu koyunun zaten bir $roleLabel var ($conflict). Değiştirmek istiyor musunuz?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Değiştir')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await DatabaseHelper.instance.setSheepParent(
        sheepId: widget.sheep.id!,
        parentId: picked.id!,
        role: role,
        force: true,
      );
    }
    if (mounted) widget.onChanged();
  }

  Future<void> _removeParent(String role) async {
    final roleLabel = role == 'mother' ? 'Anne' : 'Baba';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$roleLabel Bağlantısını Kaldır'),
        content: Text('$roleLabel bağlantısı kaldırılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Kaldır', style: TextStyle(color: AppColors.rust)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await DatabaseHelper.instance.removeSheepParent(sheepId: widget.sheep.id!, role: role);
    if (mounted) widget.onChanged();
  }

  Future<void> _linkLamb() async {
    final picked = await SheepPickerSheet.show(
      context,
      farmId: widget.sheep.farmId,
      excludeSheepId: widget.sheep.id,
    );
    if (picked == null || !mounted || picked.id == null) return;

    final role = widget.sheep.gender == 'female' ? 'mother' : 'father';
    final conflict = await DatabaseHelper.instance.setSheepParent(
      sheepId: picked.id!,
      parentId: widget.sheep.id!,
      role: role,
    );

    if (conflict == 'circular' && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Döngüsel İlişki'),
          content: Text('${picked.earTag} zaten bu koyunun soy ağacındaki atalarından biri. Aynı zamanda yavru olarak eklenemez.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
      return;
    }

    if (conflict != null && mounted) {
      final roleLabel = role == 'mother' ? 'annesi' : 'babası';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Zaten Bağlı'),
          content: Text('Bu koyunun zaten bir $roleLabel var ($conflict). Değiştirmek istiyor musunuz?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Değiştir')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await DatabaseHelper.instance.setSheepParent(
        sheepId: picked.id!,
        parentId: widget.sheep.id!,
        role: role,
        force: true,
      );
    }
    if (mounted) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = widget.lineageData;
    final sheep = widget.sheep;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineageSectionLabel(title: 'ANNE'),
          const SizedBox(height: 8),
          data?.mother != null
              ? _LineageSheepCard(
                  sheep: data!.mother!,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SheepProfileScreen(sheep: data.mother!),
                  )),
                  trailingIcon: GestureDetector(
                    onTap: () => _removeParent('mother'),
                    child: const Icon(Icons.link_off, size: 16, color: AppColors.mutedText),
                  ),
                )
              : _LineageLinkButton(label: 'Anne Bağla', onTap: () => _linkParent('mother')),

          const SizedBox(height: 16),
          _LineageSectionLabel(title: 'BABA'),
          const SizedBox(height: 8),
          data?.father != null
              ? _LineageSheepCard(
                  sheep: data!.father!,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SheepProfileScreen(sheep: data.father!),
                  )),
                  trailingIcon: GestureDetector(
                    onTap: () => _removeParent('father'),
                    child: const Icon(Icons.link_off, size: 16, color: AppColors.mutedText),
                  ),
                )
              : _LineageLinkButton(label: 'Baba Bağla', onTap: () => _linkParent('father')),

          const SizedBox(height: 16),
          _LineageSectionLabel(title: 'YAVRULAR'),
          const SizedBox(height: 8),

          if (data == null || data.litters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Kayıtlı yavru yok', style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
            )
          else
            ...data.litters.map((litter) {
              final effectiveDate = litter.birthRecord?.date ?? litter.fallbackDate;
              final dateLabel = effectiveDate != null
                  ? 'Doğum · ${_fmtDate(effectiveDate)}'
                  : 'Doğum tarihi belirsiz';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🐑 ', style: TextStyle(fontSize: 11)),
                        Text(dateLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.bark)),
                        if (litter.birthRecord?.lambCount != null) ...[
                          const SizedBox(width: 4),
                          Text('(${litter.birthRecord!.lambCount} yavru)',
                              style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                        ],
                      ],
                    ),
                  ),
                  ...litter.lambs.map((lamb) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _LineageSheepCard(
                      sheep: lamb,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SheepProfileScreen(sheep: lamb),
                      )),
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              );
            }),

          const SizedBox(height: 4),
          _LineageLinkButton(
            label: '+ Yavru Bağla',
            onTap: sheep.id != null ? _linkLamb : null,
          ),
        ],
      ),
    );
  }
}

class _LineageSectionLabel extends StatelessWidget {
  final String title;
  const _LineageSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.8),
  );
}

class _LineageSheepCard extends StatelessWidget {
  final Sheep sheep;
  final VoidCallback onTap;
  final Widget? trailingIcon;

  const _LineageSheepCard({required this.sheep, required this.onTap, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    final isFemale = sheep.gender == 'female';
    final genderColor = isFemale ? AppColors.rust : AppColors.soil;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: genderColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(isFemale ? '♀' : '♂', style: TextStyle(fontSize: 17, color: genderColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sheep.earTag, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil)),
                  const SizedBox(height: 2),
                  Text(
                    [if (sheep.name != null) sheep.name!, sheep.breed].join(' · '),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            trailingIcon ?? const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _LineageLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _LineageLinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soil.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.soil),
      ),
    ),
  );
}

// ── Notes tab ─────────────────────────────────────────────────────────────────
class _NotesTab extends StatelessWidget {
  final Sheep sheep;
  final List<SheepNote> notes;
  final bool loaded;
  final VoidCallback onNoteAdded;

  const _NotesTab({
    required this.sheep,
    required this.notes,
    required this.loaded,
    required this.onNoteAdded,
  });

  String _fmt(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                  child: notes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('Henüz not eklenmemiş', style: TextStyle(color: AppColors.mutedText)),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOTLAR',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 10),
                              ...notes.asMap().entries.map((e) {
                                final n = e.value;
                                final isLast = e.key == notes.length - 1;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 6, height: 6,
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.bark,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              n.note,
                                              style: const TextStyle(fontSize: 12, color: AppColors.soil, fontWeight: FontWeight.w400, height: 1.45),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _fmt(n.date),
                                            style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast) Divider(color: Colors.black.withValues(alpha: 0.04), height: 1),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: GestureDetector(
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNoteScreen(
                    sheepId: sheep.id!,
                    earTag: sheep.earTag,
                  ),
                ),
              );
              if (added == true) onNoteAdded();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.soil,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.soil.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Text(
                '+ Kayıt Ekle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.straw),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
