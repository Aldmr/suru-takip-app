import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  String _category = 'animal_sale';
  DateTime _date = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<Sheep> _selectedSheep = [];
  bool _isSaving = false;

  static const _categories = [
    ('animal_sale', '🐑', 'Hayvan Satışı'),
    ('wool', '🧶', 'Yapağı / Yün'),
    ('milk', '🥛', 'Süt'),
    ('other', '📦', 'Diğer'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _buyerCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSheepPicker() async {
    final picked = await showModalBottomSheet<List<Sheep>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheepPickerSheet(initialSelected: _selectedSheep),
    );
    if (picked != null) setState(() => _selectedSheep = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      showAppNotification(context, 'Geçerli bir tutar girin', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final t = FinancialTransaction(
      farmId: FarmManager.instance.activeFarmId,
      type: 'income',
      category: _category,
      amount: amount,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      buyerName: _buyerCtrl.text.trim().isEmpty ? null : _buyerCtrl.text.trim(),
      sheepIds: _selectedSheep.map((s) => s.id!).where((id) => id > 0).toList(),
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertFinancialTransaction(t);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _fmt(DateTime d) {
    const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('← Ekonomi',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Gelir Ekle',
                      style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 24, color: AppColors.soil)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Gelir Türü'),
                    const SizedBox(height: 6),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 2.8,
                      children: _categories.map((c) {
                        final selected = _category == c.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.soil.withValues(alpha: 0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected ? AppColors.soil : Colors.transparent, width: 1.5),
                              boxShadow: [
                                BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(c.$2, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(c.$3,
                                      style: const TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.soil)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_category == 'animal_sale') ...[
                      const SizedBox(height: 14),
                      _label('Satılan Koyun${_selectedSheep.isNotEmpty ? " · ${_selectedSheep.length} seçili" : ""}'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _openSheepPicker,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _selectedSheep.isNotEmpty
                                    ? AppColors.sage
                                    : Colors.transparent,
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))
                            ],
                          ),
                          child: _selectedSheep.isEmpty
                              ? Row(
                                  children: [
                                    const Icon(Icons.add, size: 16, color: AppColors.mutedText),
                                    const SizedBox(width: 6),
                                    Text('Koyun seç...',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mutedText.withValues(alpha: 0.7))),
                                  ],
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ..._selectedSheep.map((s) => _SheepPill(
                                          sheep: s,
                                          onRemove: () => setState(
                                              () => _selectedSheep.remove(s)),
                                        )),
                                    GestureDetector(
                                      onTap: _openSheepPicker,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.mist, width: 1.5,
                                              style: BorderStyle.solid),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('+ Ekle',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.mutedText)),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label('Satış Fiyatı'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sage, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                  fontFamily: 'DMSerifDisplay', fontSize: 26, color: AppColors.soil),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(
                                    fontFamily: 'DMSerifDisplay', fontSize: 26, color: AppColors.mist),
                              ),
                            ),
                          ),
                          const Text('₺',
                              style: TextStyle(
                                  fontFamily: 'DMSerifDisplay', fontSize: 22, color: AppColors.sage)),
                        ],
                      ),
                    ),
                    if (_category == 'animal_sale') ...[
                      const SizedBox(height: 14),
                      _label('Alıcı Adı'),
                      const SizedBox(height: 6),
                      _textField(_buyerCtrl, 'Alıcı adı (opsiyonel)'),
                    ],
                    const SizedBox(height: 14),
                    _label('Tarih'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: AppColors.soil, onPrimary: AppColors.straw)),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 15, color: AppColors.mutedText),
                            const SizedBox(width: 8),
                            Text(_fmt(_date),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.soil,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Not'),
                    const SizedBox(height: 6),
                    _textField(_noteCtrl, 'Varsa not ekle...'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.soil,
                    foregroundColor: AppColors.straw,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.straw))
                      : const Text('Satışı Kaydet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.bark, letterSpacing: 0.6));

  Widget _textField(TextEditingController ctrl, String hint) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13, color: AppColors.soil),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withValues(alpha: 0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}

class _SheepPill extends StatelessWidget {
  final Sheep sheep;
  final VoidCallback onRemove;

  const _SheepPill({required this.sheep, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐑', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(sheep.displayName,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.soil)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

// ── Sheep Picker Bottom Sheet ─────────────────────────────────────────────────
class _SheepPickerSheet extends StatefulWidget {
  final List<Sheep> initialSelected;

  const _SheepPickerSheet({required this.initialSelected});

  @override
  State<_SheepPickerSheet> createState() => _SheepPickerSheetState();
}

class _SheepPickerSheetState extends State<_SheepPickerSheet> {
  late List<Sheep> _selected;
  List<Sheep> _allSheep = [];
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper.instance.getAllSheep(
        farmId: FarmManager.instance.activeFarmId);
    if (mounted) {
      setState(() => _allSheep = list.where((s) => s.status != 'sold' && s.status != 'dead').toList());
    }
  }

  List<Sheep> get _filtered {
    if (_query.isEmpty) return _allSheep;
    return _allSheep.where((s) =>
        s.displayName.toLowerCase().contains(_query) ||
        s.earTag.toLowerCase().contains(_query)).toList();
  }

  void _toggle(Sheep s) {
    setState(() {
      if (_selected.any((x) => x.id == s.id)) {
        _selected.removeWhere((x) => x.id == s.id);
      } else {
        _selected.add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.wool,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(2))),
          if (_selected.isNotEmpty)
            Container(
              color: AppColors.soil,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: AppColors.straw, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${_selected.length}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.soil)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('koyun seçildi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.straw)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selected.clear()),
                    child: const Text('İptal',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 12, color: AppColors.soil),
                decoration: const InputDecoration(
                  hintText: 'Koyun ara...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.mutedText),
                  prefixIcon: Icon(Icons.search, size: 16, color: AppColors.mutedText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final s = _filtered[i];
                final isSelected = _selected.any((x) => x.id == s.id);
                final (badgeLabel, badgeBg, badgeText) = switch (s.status) {
                  'pregnant' => ('GEBELİK', AppColors.sky.withValues(alpha: 0.2), const Color(0xFF3A7FA0)),
                  'sick' => ('HASTA', AppColors.rust.withValues(alpha: 0.12), AppColors.rust),
                  _ => ('SAĞLIKLI', AppColors.sage.withValues(alpha: 0.15), const Color(0xFF4A8A49)),
                };
                return GestureDetector(
                  onTap: () => _toggle(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.sage.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected ? AppColors.sage : Colors.transparent, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.sage : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isSelected ? AppColors.sage : AppColors.mist, width: 2),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text('🐑', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.displayName,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.soil)),
                              Text('${s.earTag} · ${s.lastWeight != null ? "${s.lastWeight} kg" : s.breed}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(badgeLabel,
                              style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.w700, color: badgeText)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.soil,
                  foregroundColor: AppColors.straw,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(
                  _selected.isEmpty ? 'Seç' : '${_selected.length} Koyun Seçildi — Tamam',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
