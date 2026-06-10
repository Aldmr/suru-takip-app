import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class AddNoteScreen extends StatefulWidget {
  final int sheepId;
  final String earTag;

  const AddNoteScreen({
    super.key,
    required this.sheepId,
    required this.earTag,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
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
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_noteController.text.trim().isEmpty) {
      showAppNotification(context, 'Not alanı boş bırakılamaz', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final note = SheepNote(
      sheepId: widget.sheepId,
      date: _date,
      note: _noteController.text.trim(),
    );

    await DatabaseHelper.instance.insertSheepNote(note);
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
                    'Not Ekle',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 24,
                      color: AppColors.soil,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'TARİH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(_date),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.soil),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.mutedText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.soil),
                      decoration: const InputDecoration(
                        hintText: 'Notunuzu buraya yazın...',
                        hintStyle: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                      color: _isSaving ? AppColors.soil.withValues(alpha: 0.5) : AppColors.soil,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.soil.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.straw),
                            ),
                          )
                        : const Text(
                            'Kaydet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.straw, letterSpacing: 0.3),
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
