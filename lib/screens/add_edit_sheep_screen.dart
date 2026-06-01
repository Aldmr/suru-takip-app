import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/farm_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/sheep_picker_sheet.dart';

class AddEditSheepScreen extends StatefulWidget {
  final Sheep? sheep;
  final String? initialNfc;

  const AddEditSheepScreen({super.key, this.sheep, this.initialNfc});

  @override
  State<AddEditSheepScreen> createState() => _AddEditSheepScreenState();
}

class _AddEditSheepScreenState extends State<AddEditSheepScreen> {
  final _formKey = GlobalKey<FormState>();
  static const _breeds = ['Akkaraman', 'Merinos', 'Kıvırcık', 'İvesi', 'Karayaka'];

  late TextEditingController _earTagCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _nfcCtrl;
  late TextEditingController _weightCtrl;
  String _gender = 'female';
  String _breed = 'Akkaraman';
  String _status = 'active';
  DateTime? _birthDate;
  bool _isSaving = false;
  Sheep? _mother;
  Sheep? _father;
  List<String> _groups = [];
  String? _group;

  @override
  void initState() {
    super.initState();
    final s = widget.sheep;
    _earTagCtrl = TextEditingController(text: s?.earTag ?? '');
    if (s == null) {
      final farmId = FarmManager.instance.activeFarmId;
      if (farmId != null) {
        DatabaseHelper.instance.getNextEarTag(farmId: farmId).then((tag) {
          if (mounted) setState(() => _earTagCtrl.text = tag);
        });
      }
    }
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _nfcCtrl = TextEditingController(
      text: widget.initialNfc ?? s?.nfcUid ?? '',
    );
    _breed = _breeds.contains(s?.breed) ? (s?.breed ?? _breeds.first) : _breeds.first;
    _group = s?.groupName;
    if (_group != null) _groups = [_group!];
    _weightCtrl = TextEditingController(text: s?.lastWeight?.toString() ?? '');
    final farmId = s?.farmId ?? FarmManager.instance.activeFarmId;
    DatabaseHelper.instance.getGroups(farmId: farmId).then((groups) {
      if (mounted) {
        setState(() {
          _groups = groups;
          if (_group != null && !_groups.contains(_group)) {
            _groups = [_group!, ..._groups];
          }
        });
      }
    });
    _gender = s?.gender ?? 'female';
    _status = s?.status ?? 'active';
    _birthDate = s?.birthDate;
    if (s?.motherId != null) {
      DatabaseHelper.instance.getSheepById(s!.motherId!).then((sheep) {
        if (mounted && sheep != null) setState(() => _mother = sheep);
      });
    }
    if (s?.fatherId != null) {
      DatabaseHelper.instance.getSheepById(s!.fatherId!).then((sheep) {
        if (mounted && sheep != null) setState(() => _father = sheep);
      });
    }
  }

  @override
  void dispose() {
    _earTagCtrl.dispose();
    _nameCtrl.dispose();
    _nfcCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final earTag = _earTagCtrl.text.trim();
    final farmId = widget.sheep?.farmId ?? FarmManager.instance.activeFarmId;
    final taken = await DatabaseHelper.instance.isEarTagTaken(earTag, farmId: farmId, excludeId: widget.sheep?.id);
    if (taken) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$earTag" küpe numarası zaten kayıtlı. Her koyunun küpesi benzersiz olmalıdır.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final sheep = Sheep(
      id: widget.sheep?.id,
      nfcUid: _nfcCtrl.text.trim(),
      earTag: _earTagCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      breed: _breed,
      status: _status,
      groupName: _group,
      lastWeight: _weightCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_weightCtrl.text.trim()),
      farmId: widget.sheep?.farmId ?? FarmManager.instance.activeFarmId,
      motherId: _mother?.id,
      fatherId: _father?.id,
    );

    if (widget.sheep == null) {
      final id = await DatabaseHelper.instance.insertSheep(sheep);
      final created = sheep.copyWith(id: id);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } else {
      await DatabaseHelper.instance.updateSheep(sheep);
      if (!mounted) return;
      Navigator.of(context).pop(sheep);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sheep != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Koyun Düzenle' : 'Yeni Koyun'),
        backgroundColor: AppColors.soil,
        foregroundColor: AppColors.straw,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.wool,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Koyun bilgilerini güncelle'
                        : 'Yeni koyun ekle',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.soil,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Koyunun temel bilgilerini ve son kilosunu girerek kaydı tamamla.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            controller: _earTagCtrl,
                            label: 'Küpe No',
                            readOnly: true,
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.lock_outline, size: 16, color: AppColors.mutedText),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Tasma No',
                            hint: 'T-001',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _nfcCtrl,
                            label: 'NFC UID (opsiyonel)',
                            hint: '96:75:AC:3A:42:E9',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  initialValue: _gender,
                                  label: 'Cinsiyet',
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Dişi'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Erkek'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _gender = v ?? 'female'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  initialValue: _breed,
                                  label: 'Irk',
                                  items: _breeds.map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _breed = v ?? _breeds.first),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildDateField(),
                          const SizedBox(height: 14),
                          _buildParentField(
                            label: 'Anne (opsiyonel)',
                            parent: _mother,
                            genderFilter: 'female',
                            onPick: (s) => setState(() => _mother = s),
                            onClear: () => setState(() => _mother = null),
                          ),
                          const SizedBox(height: 14),
                          _buildParentField(
                            label: 'Baba (opsiyonel)',
                            parent: _father,
                            genderFilter: 'male',
                            onPick: (s) => setState(() => _father = s),
                            onClear: () => setState(() => _father = null),
                          ),
                          const SizedBox(height: 14),
                          _buildGroupField(),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _weightCtrl,
                            label: 'Son kilo (kg)',
                            hint: '72.4',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.soil,
                                foregroundColor: AppColors.straw,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.straw,
                                      ),
                                    )
                                  : Text(
                                      isEditing ? 'Güncelle' : 'Kaydet',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addNewGroup() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Grup'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Grup adı'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (!_groups.contains(result)) _groups = [..._groups, result];
        _group = result;
      });
    }
  }

  Widget _buildGroupField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: 0.2)),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: _group,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Grup yok', style: TextStyle(color: AppColors.mutedText)),
              ),
              ..._groups.map((g) => DropdownMenuItem<String?>(value: g, child: Text(g))),
            ],
            onChanged: (v) => setState(() => _group = v),
            decoration: InputDecoration(
              labelText: 'Grup (opsiyonel)',
              filled: true,
              fillColor: AppColors.wool,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: const TextStyle(color: AppColors.mutedText),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.soil.withValues(alpha: 0.8), width: 1.8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addNewGroup,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.soil.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.soil.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.add, color: AppColors.soil, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final formatted = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}'
        : null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: 0.2)),
    );
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.soil, onPrimary: AppColors.straw),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _birthDate = picked);
      },
      child: InputDecorator(
        isEmpty: formatted == null,
        decoration: InputDecoration(
          labelText: 'Doğum tarihi (opsiyonel)',
          filled: true,
          fillColor: AppColors.wool,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: AppColors.mutedText),
          border: border,
          enabledBorder: border,
          suffixIcon: _birthDate != null
              ? GestureDetector(
                  onTap: () => setState(() => _birthDate = null),
                  child: const Icon(Icons.clear, size: 18, color: AppColors.mutedText),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.mutedText),
        ),
        child: Text(
          formatted ?? '',
          style: const TextStyle(fontSize: 16, color: AppColors.soil),
        ),
      ),
    );
  }

  Widget _buildParentField({
    required String label,
    required Sheep? parent,
    required String genderFilter,
    required ValueChanged<Sheep?> onPick,
    required VoidCallback onClear,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: 0.2)),
    );
    final farmId = widget.sheep?.farmId ?? FarmManager.instance.activeFarmId;
    return GestureDetector(
      onTap: () async {
        final picked = await SheepPickerSheet.show(
          context,
          farmId: farmId,
          genderFilter: genderFilter,
          excludeSheepId: widget.sheep?.id,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        isEmpty: parent == null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.wool,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: AppColors.mutedText),
          border: border,
          enabledBorder: border,
          suffixIcon: parent != null
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.clear, size: 18, color: AppColors.mutedText),
                )
              : const Icon(Icons.link, size: 18, color: AppColors.mutedText),
        ),
        child: Text(
          parent == null
              ? ''
              : '${parent.earTag}${parent.name != null ? ' · ${parent.name}' : ''}',
          style: const TextStyle(fontSize: 16, color: AppColors.soil),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    final isReadOnly = readOnly;
    final fillColor = isReadOnly ? AppColors.mist.withValues(alpha: 0.3) : AppColors.wool;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: isReadOnly ? 0.1 : 0.2)),
    );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: isReadOnly,
      style: TextStyle(
        fontSize: 16,
        color: isReadOnly ? AppColors.mutedText : AppColors.soil,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.mutedText),
        suffixIcon: suffixIcon,
        border: border,
        enabledBorder: border,
        focusedBorder: isReadOnly
            ? border
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.soil.withValues(alpha: 0.8), width: 1.8),
              ),
      ),
    );
  }

  Widget _buildDropdown({
    required String initialValue,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.wool,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AppColors.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.mutedText.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.soil.withValues(alpha: 0.8),
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
