import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../widgets/sheep_picker_sheet.dart';

class AddBreedingRecordScreen extends StatefulWidget {
  final int sheepId;
  final String sheepName;
  final String earTag;
  final int? farmId;

  const AddBreedingRecordScreen({
    super.key,
    required this.sheepId,
    required this.sheepName,
    required this.earTag,
    this.farmId,
  });

  @override
  State<AddBreedingRecordScreen> createState() =>
      _AddBreedingRecordScreenState();
}

class _AddBreedingRecordScreenState extends State<AddBreedingRecordScreen> {
  String _type = 'mating';
  DateTime _date = DateTime.now();
  DateTime? _expectedBirth;
  final _lambCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Sheep? _selectedRam;
  bool _isSaving = false;

  @override
  void dispose() {
    _lambCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final lambCount = _type == 'birth' ? (int.tryParse(_lambCtrl.text.trim()) ?? 0) : 0;
    final recordId = await DatabaseHelper.instance.insertBreedingRecord(
      BreedingRecord(
        sheepId: widget.sheepId,
        type: _type,
        date: _date,
        expectedBirth: _type == 'pregnancy' ? _expectedBirth : null,
        lambCount: lambCount > 0 ? lambCount : null,
        partnerUid: _selectedRam?.earTag,
        partnerSheepId: _selectedRam?.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    if (_type == 'birth' && lambCount > 0 && mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LambLinkSheet(
          motherSheepId: widget.sheepId,
          farmId: widget.farmId,
          birthRecordId: recordId,
          lambCount: lambCount,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      appBar: AppBar(
        title: Text(
          widget.earTag,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.straw,
          ),
        ),
        backgroundColor: AppColors.soil,
        foregroundColor: AppColors.straw,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Üreme Kaydı Ekle',
              style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 24,
                color: AppColors.soil,
              ),
            ),
            const SizedBox(height: 18),
            // Type selector
            const Text(
              'Kayıt türü',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Çiftleşme',
                  value: 'mating',
                  group: _type,
                  onTap: () => setState(() => _type = 'mating'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Gebelik',
                  value: 'pregnancy',
                  group: _type,
                  onTap: () => setState(() => _type = 'pregnancy'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Doğum',
                  value: 'birth',
                  group: _type,
                  onTap: () => setState(() => _type = 'birth'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Event date
            _SectionLabel(
              text: _type == 'mating'
                  ? 'Çiftleşme tarihi'
                  : _type == 'pregnancy'
                  ? 'Gebelik başlangıcı'
                  : 'Doğum tarihi',
            ),
            const SizedBox(height: 6),
            _DateRow(
              date: _date,
              label: _formatDate(_date),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now(),
                  builder: _datePicker,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            // Conditional fields
            if (_type == 'pregnancy') ...[
              const SizedBox(height: 14),
              _SectionLabel(text: 'Tahmini doğum tarihi (opsiyonel)'),
              const SizedBox(height: 6),
              _DateRow(
                date: _expectedBirth,
                label: _expectedBirth != null
                    ? _formatDate(_expectedBirth!)
                    : 'Seçiniz',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _expectedBirth ?? _date.add(const Duration(days: 147)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: _datePicker,
                  );
                  if (picked != null) setState(() => _expectedBirth = picked);
                },
              ),
            ],
            if (_type == 'birth') ...[
              const SizedBox(height: 14),
              _SectionLabel(text: 'Yavru sayısı'),
              const SizedBox(height: 6),
              _Field(
                controller: _lambCtrl,
                hint: '1',
                keyboardType: TextInputType.number,
              ),
            ],
            if (_type == 'mating') ...[
              const SizedBox(height: 14),
              _SectionLabel(text: 'Koç (opsiyonel)'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await SheepPickerSheet.show(
                    context,
                    farmId: widget.farmId,
                    genderFilter: 'male',
                    excludeSheepId: widget.sheepId,
                  );
                  if (picked != null) setState(() => _selectedRam = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: _selectedRam != null
                        ? Border.all(color: AppColors.sage.withValues(alpha: 0.5), width: 1.5)
                        : null,
                    boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.soil.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('♂', style: TextStyle(fontSize: 16, color: AppColors.soil))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedRam == null
                            ? const Text('Seçiniz', style: TextStyle(fontSize: 13, color: AppColors.mutedText))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedRam!.earTag,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil),
                                  ),
                                  if (_selectedRam!.name != null)
                                    Text(_selectedRam!.name!, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                                ],
                              ),
                      ),
                      if (_selectedRam != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedRam = null),
                          child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                        )
                      else
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedText),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _SectionLabel(text: 'Not (opsiyonel)'),
            const SizedBox(height: 6),
            _Field(controller: _notesCtrl, hint: 'Gözlemler...', maxLines: 3),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.soil,
                  foregroundColor: AppColors.straw,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.straw,
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext c, Widget? child) => Theme(
    data: Theme.of(c).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.soil,
        onPrimary: AppColors.straw,
      ),
    ),
    child: child!,
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == group;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.soil : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.soil : const Color(0xFFE8DFD0),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.soil.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.straw : AppColors.bark,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.mutedText,
      letterSpacing: 0.3,
    ),
  );
}

class _DateRow extends StatelessWidget {
  final DateTime? date;
  final String label;
  final VoidCallback onTap;

  const _DateRow({
    required this.date,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.soil,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 13, color: AppColors.soil),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedText),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    ),
  );
}

// ── Lamb link sheet ───────────────────────────────────────────────────────────
class _LambLinkSheet extends StatefulWidget {
  final int motherSheepId;
  final int? farmId;
  final int birthRecordId;
  final int lambCount;

  const _LambLinkSheet({
    required this.motherSheepId,
    required this.farmId,
    required this.birthRecordId,
    required this.lambCount,
  });

  @override
  State<_LambLinkSheet> createState() => _LambLinkSheetState();
}

class _LambLinkSheetState extends State<_LambLinkSheet> {
  late List<Sheep?> _linked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _linked = List.filled(widget.lambCount, null);
  }

  Future<void> _pickForSlot(int index) async {
    final picked = await SheepPickerSheet.show(
      context,
      farmId: widget.farmId,
      excludeSheepId: widget.motherSheepId,
    );
    if (picked == null || !mounted) return;
    setState(() => _linked[index] = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    for (final lamb in _linked) {
      if (lamb?.id == null) continue;
      await DatabaseHelper.instance.setSheepParent(
        sheepId: lamb!.id!,
        parentId: widget.motherSheepId,
        role: 'mother',
        force: true,
      );
      await DatabaseHelper.instance.linkLambToBirth(
        sheepId: lamb.id!,
        birthRecordId: widget.birthRecordId,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.wool,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Yavruları Bağla',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.soil),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Her yavruyu koyun kaydıyla eşleştirin (opsiyonel)',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.lambCount,
                itemBuilder: (_, i) {
                  final lamb = _linked[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _pickForSlot(i),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lamb != null
                                ? AppColors.sage.withValues(alpha: 0.4)
                                : AppColors.mutedText.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.soil.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.soil),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: lamb == null
                                  ? const Text('Koyun seç...', style: TextStyle(fontSize: 13, color: AppColors.mutedText))
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lamb.earTag, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil)),
                                        if (lamb.name != null)
                                          Text(lamb.name!, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                                      ],
                                    ),
                            ),
                            Icon(
                              lamb != null ? Icons.check_circle_outline : Icons.add_circle_outline,
                              size: 18,
                              color: lamb != null ? AppColors.sage : AppColors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving ? null : () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.mutedText.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Atla',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: AppColors.mutedText, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.soil,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _saving
                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.straw)))
                                : const Text(
                                    'Tamamla',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: AppColors.straw, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
