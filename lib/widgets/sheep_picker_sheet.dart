import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class SheepPickerSheet extends StatefulWidget {
  final int? farmId;
  final String? genderFilter;
  final int? excludeSheepId;

  const SheepPickerSheet({
    super.key,
    this.farmId,
    this.genderFilter,
    this.excludeSheepId,
  });

  static Future<Sheep?> show(
    BuildContext context, {
    int? farmId,
    String? genderFilter,
    int? excludeSheepId,
  }) {
    return showModalBottomSheet<Sheep>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheepPickerSheet(
        farmId: farmId,
        genderFilter: genderFilter,
        excludeSheepId: excludeSheepId,
      ),
    );
  }

  @override
  State<SheepPickerSheet> createState() => _SheepPickerSheetState();
}

class _SheepPickerSheetState extends State<SheepPickerSheet> {
  List<Sheep> _all = [];
  List<Sheep> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sheep = await DatabaseHelper.instance.getAllSheep(
      farmId: widget.farmId,
      activeOnly: false,
    );
    final filtered = sheep.where((s) {
      if (s.id == widget.excludeSheepId) return false;
      if (widget.genderFilter != null && s.gender != widget.genderFilter) return false;
      if (s.status == 'sold' || s.status == 'dead') return false;
      return true;
    }).toList();
    if (!mounted) return;
    setState(() {
      _all = filtered;
      _filtered = filtered;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((s) =>
              s.earTag.toLowerCase().contains(q) ||
              (s.name?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  String get _title {
    if (widget.genderFilter == 'female') return 'Anne Seç';
    if (widget.genderFilter == 'male') return 'Baba Seç';
    return 'Koyun Seç';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.wool,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                _title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.soil),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13, color: AppColors.soil),
                decoration: InputDecoration(
                  hintText: 'Küpe no veya isim ara...',
                  hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text('Koyun bulunamadı',
                              style: TextStyle(color: AppColors.mutedText)),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            final isFemale = s.gender == 'female';
                            final genderColor = isFemale ? AppColors.rust : AppColors.soil;
                            return GestureDetector(
                              onTap: () => Navigator.pop(context, s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: genderColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          isFemale ? '♀' : '♂',
                                          style: TextStyle(fontSize: 16, color: genderColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.earTag,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.soil),
                                          ),
                                          if (s.name != null) ...[
                                            const SizedBox(height: 1),
                                            Text(s.name!, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(s.breed, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
