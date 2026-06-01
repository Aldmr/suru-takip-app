import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/bottom_nav.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import 'sheep_profile_screen.dart';
import 'add_edit_sheep_screen.dart';

class SheepListScreen extends StatefulWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const SheepListScreen({
    super.key,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  State<SheepListScreen> createState() => _SheepListScreenState();
}

class _SheepListScreenState extends State<SheepListScreen> {
  String _activeFilter = 'Tümü';
  final _filters = ['Tümü', 'Dişi', 'Erkek', 'Hasta', 'Gebe', 'Satıldı'];
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _groupFilter;
  List<String> _groups = [];

  List<Sheep> _sheep = [];
  List<SoldSheepRecord> _soldSheep = [];

  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  bool get _isSoldMode => _activeFilter == 'Satıldı';

  @override
  void initState() {
    super.initState();
    FarmManager.instance.addListener(_onFarmChanged);
    _loadSheep();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    FarmManager.instance.removeListener(_onFarmChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onFarmChanged() {
    if (!mounted) return;
    setState(() {
      _sheep = [];
      _soldSheep = [];
      _groupFilter = null;
    });
    _loadSheep();
    if (_isSoldMode) _loadSoldSheep();
  }

  Future<void> _loadSheep() async {
    final farmId = FarmManager.instance.activeFarmId;
    await DatabaseHelper.instance.syncSheepStatuses(farmId: farmId);
    final results = await Future.wait([
      DatabaseHelper.instance.getAllSheep(farmId: farmId, activeOnly: true),
      DatabaseHelper.instance.getGroups(farmId: farmId),
    ]);
    if (mounted) {
      setState(() {
        _sheep = results[0] as List<Sheep>;
        _groups = results[1] as List<String>;
        if (_groupFilter != null && !_groups.contains(_groupFilter)) {
          _groupFilter = null;
        }
      });
    }
  }

  Future<void> _loadSoldSheep() async {
    final list = await DatabaseHelper.instance
        .getSoldSheepWithInfo(farmId: FarmManager.instance.activeFarmId);
    if (mounted) setState(() => _soldSheep = list);
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _showBulkVaccineSheet() async {
    final nameCtrl = TextEditingController();
    var date = DateTime.now();
    DateTime? nextDate;

    String fmt(DateTime d) {
      const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${d.day} ${m[d.month]} ${d.year}';
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.wool,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_selectedIds.length} Koyuna Toplu Aşı',
                  style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 20, color: AppColors.soil),
                ),
                const SizedBox(height: 16),
                const Text('Aşı adı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.soil),
                  decoration: InputDecoration(
                    hintText: 'Brucellosis, Şap, Enterotoksemi...',
                    hintStyle: const TextStyle(color: AppColors.mutedText),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tarih', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final p = await showDatePicker(
                                context: ctx,
                                initialDate: date,
                                firstDate: DateTime(2015),
                                lastDate: DateTime.now(),
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.soil, onPrimary: AppColors.straw)),
                                  child: child!,
                                ),
                              );
                              if (p != null) setSheet(() => date = p);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mutedText),
                                const SizedBox(width: 6),
                                Text(fmt(date), style: const TextStyle(fontSize: 12, color: AppColors.soil)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sonraki doz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final p = await showDatePicker(
                                context: ctx,
                                initialDate: nextDate ?? date.add(const Duration(days: 365)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 1825)),
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.soil, onPrimary: AppColors.straw)),
                                  child: child!,
                                ),
                              );
                              if (p != null) setSheet(() => nextDate = p);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mutedText),
                                const SizedBox(width: 6),
                                Text(nextDate != null ? fmt(nextDate!) : 'Opsiyonel', style: TextStyle(fontSize: 12, color: nextDate != null ? AppColors.soil : AppColors.mutedText)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.soil,
                      foregroundColor: AppColors.straw,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('Kaydet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // nameCtrl.dispose() burada çağrılmaz: modal kapanış animasyonu devam
    // ederken TextField hâlâ controller'a bağlı; dispose erken çağrılırsa
    // ChangeNotifier "used after dispose" hatası fırlatır. GC halleder.
    final savedName = nameCtrl.text.trim();
    final savedCount = _selectedIds.length;
    final savedIds = _selectedIds.toList();

    if (ok == true) {
      await DatabaseHelper.instance.insertBulkVaccine(
        sheepIds: savedIds,
        vaccineName: savedName.isEmpty ? 'Aşı' : savedName,
        date: date,
        nextDate: nextDate,
      );
      if (!mounted) return;
      _exitSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount koyuna aşı kaydedildi'),
            backgroundColor: AppColors.sage,
          ),
        );
      }
    }
  }

  Future<void> _showBulkSaleSheet() async {
    final priceCtrl = TextEditingController();
    final buyerCtrl = TextEditingController();
    var date = DateTime.now();

    String fmt(DateTime d) {
      const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${d.day} ${m[d.month]} ${d.year}';
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.wool,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_selectedIds.length} Koyunu Sat',
                    style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 20, color: AppColors.soil),
                  ),
                  const SizedBox(height: 16),
                  const Text('Toplam Satış Fiyatı',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sage, width: 1.5),
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                                fontFamily: 'DMSerifDisplay', fontSize: 24, color: AppColors.soil),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                  fontFamily: 'DMSerifDisplay', fontSize: 24, color: AppColors.mist),
                            ),
                          ),
                        ),
                        const Text('₺',
                            style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 20, color: AppColors.sage)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alıcı',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
                              ),
                              child: TextField(
                                controller: buyerCtrl,
                                style: const TextStyle(fontSize: 12, color: AppColors.soil),
                                decoration: const InputDecoration(
                                  hintText: 'Opsiyonel',
                                  hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 12),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tarih',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.3)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final p = await showDatePicker(
                                  context: ctx,
                                  initialDate: date,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now(),
                                  builder: (c, child) => Theme(
                                    data: Theme.of(c).copyWith(
                                        colorScheme: const ColorScheme.light(
                                            primary: AppColors.soil, onPrimary: AppColors.straw)),
                                    child: child!,
                                  ),
                                );
                                if (p != null) setSheet(() => date = p);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
                                ),
                                child: Row(children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mutedText),
                                  const SizedBox(width: 6),
                                  Text(fmt(date), style: const TextStyle(fontSize: 12, color: AppColors.soil)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sage,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (priceCtrl.text.trim().isEmpty) return;
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('Satışı Kaydet',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
    final buyer = buyerCtrl.text.trim();
    final savedIds = _selectedIds.toList();
    final savedCount = savedIds.length;

    if (ok == true && price != null && price > 0) {
      final t = FinancialTransaction(
        farmId: FarmManager.instance.activeFarmId,
        type: 'income',
        category: 'animal_sale',
        amount: price,
        date: date,
        buyerName: buyer.isEmpty ? null : buyer,
        sheepIds: savedIds,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertFinancialTransaction(t);
      if (!mounted) return;
      _exitSelection();
      await _loadSheep();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount koyun satışı kaydedildi'),
            backgroundColor: AppColors.sage,
          ),
        );
      }
    }
  }

  List<Sheep> get _filtered {
    var list = _sheep;

    switch (_activeFilter) {
      case 'Dişi':
        list = list.where((s) => s.gender == 'female').toList();
      case 'Erkek':
        list = list.where((s) => s.gender == 'male').toList();
      case 'Hasta':
        list = list.where((s) => s.status == 'sick').toList();
      case 'Gebe':
        list = list.where((s) => s.isPregnant).toList();
    }

    if (_groupFilter != null) {
      list = list.where((s) => s.groupName == _groupFilter).toList();
    }

    if (_query.isNotEmpty) {
      list = list.where((s) =>
        s.earTag.toLowerCase().contains(_query) ||
        (s.name?.toLowerCase().contains(_query) ?? false) ||
        s.breed.toLowerCase().contains(_query),
      ).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Sürü Listesi',
                            style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 26, color: AppColors.soil),
                          ),
                          const Spacer(),
                          if (!_selectionMode)
                            GestureDetector(
                              onTap: () async {
                                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditSheepScreen()));
                                if (res != null) await _loadSheep();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.soil,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add, color: AppColors.straw, size: 20),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 12, color: AppColors.soil),
                          decoration: InputDecoration(
                            hintText: 'Küpe no veya isim ara...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 6),
                              child: Text('🔍', style: TextStyle(fontSize: 14)),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _searchCtrl.clear(),
                                    child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_groups.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _groups.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final g = _groups[i];
                        final isActive = g == _groupFilter;
                        return GestureDetector(
                          onTap: () => setState(() => _groupFilter = isActive ? null : g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.bark : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? AppColors.bark : const Color(0xFFE8DFD0),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📂', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? AppColors.straw : AppColors.bark,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final isActive = f == _activeFilter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _activeFilter = f);
                          if (f == 'Satıldı') _loadSoldSheep();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.soil : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? AppColors.soil : const Color(0xFFE8DFD0),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.straw : AppColors.bark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSoldMode
                ? _soldSheep.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz satılan hayvan yok',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: _soldSheep.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _SoldSheepCard(record: _soldSheep[i]),
                      )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final sheep = _filtered[i];
                      final isSelected = _selectedIds.contains(sheep.id);
                      return _SheepCard(
                        sheep: sheep,
                        selectionMode: _selectionMode,
                        isSelected: isSelected,
                        onLongPress: () {
                          if (sheep.id == null) return;
                          setState(() => _selectionMode = true);
                          _toggleSelection(sheep.id!);
                        },
                        onTap: () async {
                          if (_selectionMode) {
                            if (sheep.id != null) _toggleSelection(sheep.id!);
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SheepProfileScreen(sheep: sheep)),
                          );
                          await _loadSheep();
                        },
                        onEdit: _selectionMode
                            ? null
                            : () async {
                                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditSheepScreen(sheep: sheep)));
                                if (res != null) await _loadSheep();
                              },
                        onDelete: _selectionMode
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Silme Onayı'),
                                    content: const Text('Bu koyunu silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('İptal')),
                                      TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (ok == true && sheep.id != null) {
                                  await DatabaseHelper.instance.deleteSheep(sheep.id!);
                                  await _loadSheep();
                                }
                              },
                      );
                    },
                  ),
          ),
          if (_selectionMode)
            _SelectionBar(
              count: _selectedIds.length,
              onCancel: _exitSelection,
              onVaccine: _showBulkVaccineSheet,
              onSale: _showBulkSaleSheet,
            ),
          AppBottomNav(currentIndex: widget.navIndex, onTap: widget.onNavTap),
        ],
      ),
    );
  }
}

class _SheepCard extends StatelessWidget {
  final Sheep sheep;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const _SheepCard({
    required this.sheep,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  String get _birthDateStr {
    if (sheep.birthDate == null) return '—';
    final d = sheep.birthDate!;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Color get _avatarBg {
    if (sheep.status == 'sick') return AppColors.rust.withValues(alpha: 0.1);
    if (sheep.isPregnant) return AppColors.sky.withValues(alpha: 0.15);
    return AppColors.sage.withValues(alpha: 0.15);
  }

  (String, Color, Color) get _healthBadge {
    if (sheep.status == 'sick') {
      return ('HASTA', AppColors.rust.withValues(alpha: 0.12), AppColors.rust);
    }
    return ('SAĞLIKLI', AppColors.sage.withValues(alpha: 0.15), const Color(0xFF4A8A49));
  }

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = _healthBadge;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.soil.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.soil, width: 1.5) : null,
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.soil : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.soil : AppColors.mutedText,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: AppColors.straw)
                    : null,
              ),
              const SizedBox(width: 10),
            ],
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: _avatarBg, borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('🐑', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheep.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.soil),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sheep.earTag} · $_birthDateStr · ${sheep.breed}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            if (!selectionMode) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sheep.isPregnant)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sky.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('GEBE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                              color: Color(0xFF3A7FA0), letterSpacing: 0.5)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(label,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: textColor, letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoldSheepCard extends StatelessWidget {
  final SoldSheepRecord record;

  const _SoldSheepCard({required this.record});

  String _fmtDate(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmtAmount(double a) {
    if (a >= 1000) return '${(a / 1000).toStringAsFixed(a % 1000 == 0 ? 0 : 1)}B ₺';
    return '${a.toStringAsFixed(0)} ₺';
  }

  @override
  Widget build(BuildContext context) {
    final sheep = record.sheep;
    final details = [
      if (record.saleDate != null) _fmtDate(record.saleDate!),
      if (record.buyerName != null) record.buyerName!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bark.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🐑', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheep.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.soil),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sheep.earTag} · ${sheep.breed}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(details, style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bark.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SATILDI',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.bark, letterSpacing: 0.5),
                ),
              ),
              if (record.salePrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  _fmtAmount(record.salePrice!),
                  style: const TextStyle(
                      fontFamily: 'DMSerifDisplay', fontSize: 14, color: AppColors.soil),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onVaccine;
  final VoidCallback onSale;

  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onVaccine,
    required this.onSale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x0F000000), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close, color: AppColors.mutedText, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count koyun seçildi',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.soil,
              foregroundColor: AppColors.straw,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onPressed: count == 0 ? null : onVaccine,
            icon: const Text('💉', style: TextStyle(fontSize: 13)),
            label: const Text('Toplu Aşı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onPressed: count == 0 ? null : onSale,
            icon: const Text('💰', style: TextStyle(fontSize: 13)),
            label: const Text('Toplu Sat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
