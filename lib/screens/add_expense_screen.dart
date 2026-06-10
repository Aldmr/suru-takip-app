import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _category = 'feed';
  String _scope = 'farm';
  DateTime _date = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  static const _categories = [
    ('feed', '🌾', 'Yem'),
    ('vaccine', '💉', 'Aşı'),
    ('medicine', '💊', 'İlaç'),
    ('vet', '🩺', 'Veteriner'),
    ('maintenance', '🔧', 'Bakım'),
    ('misc', '📦', 'Çeşitli'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
      type: 'expense',
      category: _category,
      amount: amount,
      date: _date,
      note: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      scope: _scope,
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
                  const Text('Gider Ekle',
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
                    _label('Kategori'),
                    const SizedBox(height: 6),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.5,
                      children: _categories.map((c) {
                        final selected = _category == c.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.rust.withValues(alpha: 0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.rust : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(c.$2, style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 3),
                                Text(c.$3,
                                    style: const TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.soil)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Kapsam'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _scopeBtn('farm', 'Sürü Geneli')),
                        const SizedBox(width: 8),
                        Expanded(child: _scopeBtn('sheep', 'Belirli Koyun')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Tutar'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.rust, width: 1.5),
                        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
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
                                  fontFamily: 'DMSerifDisplay', fontSize: 22, color: AppColors.rust)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Tarih'),
                    const SizedBox(height: 6),
                    _dateTile(),
                    const SizedBox(height: 14),
                    _label('Açıklama'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: TextField(
                        controller: _descCtrl,
                        style: const TextStyle(fontSize: 13, color: AppColors.soil),
                        decoration: InputDecoration(
                          hintText: 'Varsa açıklama...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText.withValues(alpha: 0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
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
                    backgroundColor: AppColors.rust,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.rust.withValues(alpha: 0.35),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gideri Kaydet',
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

  Widget _scopeBtn(String value, String label) {
    final selected = _scope == value;
    return GestureDetector(
      onTap: () => setState(() => _scope = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.rust.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.rust : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 8, height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.rust : AppColors.mist),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.soil)),
          ],
        ),
      ),
    );
  }

  Widget _dateTile() {
    return GestureDetector(
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
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.mutedText),
            const SizedBox(width: 8),
            Text(_fmt(_date),
                style: const TextStyle(fontSize: 13, color: AppColors.soil, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
