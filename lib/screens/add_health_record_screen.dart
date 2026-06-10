import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final int sheepId;
  final String sheepName;
  final String earTag;

  const AddHealthRecordScreen({
    super.key,
    required this.sheepId,
    required this.sheepName,
    required this.earTag,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  int _selectedType = 0;
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _nextDate;
  bool _isSaving = false;

  final _types = [
    ('💉', 'Aşı'),
    ('🤒', 'Hastalık'),
    ('💊', 'İlaç'),
    ('🩺', 'Muayene'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _typeKey {
    switch (_selectedType) {
      case 1:
        return 'disease';
      case 2:
        return 'medicine';
      case 3:
        return 'exam';
      default:
        return 'vaccine';
    }
  }

  String get _fieldLabel {
    switch (_selectedType) {
      case 1:
        return 'Hastalık Adı';
      case 2:
        return 'İlaç Adı';
      case 3:
        return 'Muayene Notu';
      default:
        return 'Aşı Adı';
    }
  }

  bool get _showNextDate => _selectedType == 0 || _selectedType == 1 || _selectedType == 2;

  String get _nextDateLabel {
    if (_selectedType == 1) return 'BİTİŞ TARİHİ';
    return 'SONRAKİ DOZ';
  }

  String _formatDate(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
    const names = [
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
    return names[m];
  }

  Future<void> _pickDate({required bool isNext}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext
          ? (_nextDate ?? _date.add(const Duration(days: 180)))
          : _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.soil,
            onPrimary: AppColors.straw,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isNext) {
        _nextDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showAppNotification(context, 'Ad alanı boş bırakılamaz', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final now = DateTime.now();
    // Hastalık kaydı her zaman aktif (pending) başlar — kullanıcı iyileşince işaretler
    // Diğer türlerde tarih geçmişse done, gelecekse pending
    String status;
    if (_typeKey == 'disease') {
      status = 'pending';
    } else if (_date.isAfter(now)) {
      status = 'pending';
    } else {
      status = 'done';
    }

    final record = HealthRecord(
      sheepId: widget.sheepId,
      type: _typeKey,
      name: _nameController.text.trim(),
      date: _date,
      nextDate: _showNextDate ? _nextDate : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: status,
    );

    await DatabaseHelper.instance.insertHealthRecord(record);
    if (!mounted) return;
    Navigator.pop(context, true);
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sağlık Kaydı Ekle',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 24,
                      color: AppColors.soil,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Type selector
                  _FieldLabel('KAYIT TÜRÜ'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              index: 0,
                              entry: _types[0],
                              selected: _selectedType,
                              onTap: (i) => setState(() => _selectedType = i),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _TypeButton(
                              index: 1,
                              entry: _types[1],
                              selected: _selectedType,
                              onTap: (i) => setState(() => _selectedType = i),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              index: 2,
                              entry: _types[2],
                              selected: _selectedType,
                              onTap: (i) => setState(() => _selectedType = i),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _TypeButton(
                              index: 3,
                              entry: _types[3],
                              selected: _selectedType,
                              onTap: (i) => setState(() => _selectedType = i),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name field
                  _FieldLabel(_fieldLabel.toUpperCase()),
                  const SizedBox(height: 5),
                  _InputField(controller: _nameController, hint: _fieldLabel),
                  const SizedBox(height: 12),

                  // Date
                  _FieldLabel('TARİH'),
                  const SizedBox(height: 5),
                  _DateButton(
                    label: _formatDate(_date),
                    onTap: () => _pickDate(isNext: false),
                  ),
                  const SizedBox(height: 12),

                  // Next date
                  if (_showNextDate) ...[
                    _FieldLabel(_nextDateLabel),
                    const SizedBox(height: 5),
                    _DateButton(
                      label: _nextDate != null
                          ? _formatDate(_nextDate!)
                          : 'Tarih seç...',
                      muted: _nextDate == null,
                      onTap: () => _pickDate(isNext: true),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Notes
                  _FieldLabel('NOTLAR'),
                  const SizedBox(height: 5),
                  _InputField(
                    controller: _notesController,
                    hint: 'Varsa not ekle...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _isSaving
                          ? AppColors.soil.withValues(alpha: 0.5)
                          : AppColors.soil,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.soil.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.straw,
                              ),
                            ),
                          )
                        : const Text(
                            'Kaydet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.straw,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.bark,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const _InputField({required this.controller, this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.soil,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final int index;
  final (String, String) entry;
  final int selected;
  final ValueChanged<int> onTap;

  const _TypeButton({
    required this.index,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.soil.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.soil : Colors.transparent,
            width: 1.5,
          ),
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
            Text(entry.$1, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              entry.$2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.soil,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final bool muted;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: muted ? AppColors.mutedText : AppColors.soil,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
