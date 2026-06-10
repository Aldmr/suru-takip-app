import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class WeightChartScreen extends StatefulWidget {
  final Sheep sheep;

  const WeightChartScreen({super.key, required this.sheep});

  @override
  State<WeightChartScreen> createState() => _WeightChartScreenState();
}

class _WeightChartScreenState extends State<WeightChartScreen> {
  List<WeightRecord> _records = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (widget.sheep.id == null) return;
    final list = await DatabaseHelper.instance.getWeightRecordsBySheepId(widget.sheep.id!);
    if (!mounted) return;
    setState(() {
      _records = list..sort((a, b) => a.date.compareTo(b.date));
      _loaded = true;
    });
  }

  Future<void> _showAddWeightDialog() async {
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    String formatDate(DateTime d) {
      const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      return '${d.day} ${months[d.month]} ${d.year}';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.wool,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tartım Ekle',
                        style: TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 22,
                          color: AppColors.soil,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Weight field
                  TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 28, fontFamily: 'DMSerifDisplay', color: AppColors.soil),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: const TextStyle(fontSize: 28, fontFamily: 'DMSerifDisplay', color: AppColors.mutedText),
                      suffixText: 'kg',
                      suffixStyle: const TextStyle(fontSize: 16, color: AppColors.mutedText),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date picker row
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now(),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.soil,
                              onPrimary: AppColors.straw,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setModal(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.mutedText),
                          const SizedBox(width: 10),
                          Text(
                            formatDate(selectedDate),
                            style: const TextStyle(fontSize: 13, color: AppColors.soil, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(fontSize: 13, color: AppColors.soil),
                    decoration: InputDecoration(
                      hintText: 'Not (opsiyonel)',
                      hintStyle: const TextStyle(color: AppColors.mutedText),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.soil,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final kg = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
                        if (kg == null || kg <= 0) {
                          showAppNotification(context, 'Geçerli bir ağırlık girin', isError: true);
                          return;
                        }
                        await DatabaseHelper.instance.insertWeightRecord(WeightRecord(
                          sheepId: widget.sheep.id!,
                          date: selectedDate,
                          weightKg: kg,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        ));
                        // update lastWeight on the sheep record
                        await DatabaseHelper.instance.updateSheep(widget.sheep.copyWith(lastWeight: kg));
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, true);
                      },
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.straw),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('← Geri', style: TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tartım Takibi',
                        style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 24, color: AppColors.soil),
                      ),
                      Text(
                        '${widget.sheep.displayName} · Tüm kayıtlar',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loaded && _records.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _WeightChartCard(records: _records),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: Text(
                  'KAYITLAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedText,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: !_loaded
                    ? const Center(child: CircularProgressIndicator())
                    : _records.isEmpty
                        ? const Center(
                            child: Text('Henüz tartım kaydı yok', style: TextStyle(color: AppColors.mutedText)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                            itemCount: _records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final idx = _records.length - 1 - i;
                              final r = _records[idx];
                              final prev = idx > 0 ? _records[idx - 1] : null;
                              final diff = prev != null ? r.weightKg - prev.weightKg : null;
                              return _WeightEntry(record: r, diff: diff);
                            },
                          ),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 24,
            right: 18,
            child: GestureDetector(
              onTap: _showAddWeightDialog,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.soil,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.soil.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: const Center(
                  child: Text('＋', style: TextStyle(fontSize: 22, color: AppColors.straw)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────
class _WeightChartCard extends StatelessWidget {
  final List<WeightRecord> records;

  const _WeightChartCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final latest = records.isNotEmpty ? records.last.weightKg : 0.0;
    final months = records.map((r) {
      const short = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return short[r.date.month];
    }).toList();

    // Show at most 7 month labels evenly
    final labelCount = months.length <= 7 ? months.length : 7;
    final step = (months.length / labelCount).ceil();
    final labels = [
      for (var i = 0; i < months.length; i += step) months[i],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ağırlık Gelişimi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.soil),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    latest.toStringAsFixed(1),
                    style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 22, color: AppColors.sage),
                  ),
                  const Text(' kg', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _ChartPainter(records: records),
              child: Container(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((m) => Text(
              m,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.mutedText),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WeightRecord> records;

  _ChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.length < 2) return;

    final minW = records.map((r) => r.weightKg).reduce((a, b) => a < b ? a : b) - 2;
    final maxW = records.map((r) => r.weightKg).reduce((a, b) => a > b ? a : b) + 2;
    final range = maxW - minW;

    List<Offset> points = [];
    for (var i = 0; i < records.length; i++) {
      final x = (i / (records.length - 1)) * size.width;
      final y = size.height - ((records[i].weightKg - minW) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.mist
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Area fill
    final areaPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sage.withValues(alpha: 0.3), AppColors.sage.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.sage
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    final dotPaint = Paint()..color = AppColors.sage;
    for (var i = 0; i < points.length; i++) {
      if (i == points.length - 1) {
        canvas.drawCircle(points[i], 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          points[i], 5,
          Paint()
            ..color = AppColors.sage
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawCircle(points[i], 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Weight entry row ──────────────────────────────────────────────────────────
class _WeightEntry extends StatelessWidget {
  final WeightRecord record;
  final double? diff;

  const _WeightEntry({required this.record, this.diff});

  String get _dateStr {
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${record.date.day} ${months[record.date.month]} ${record.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUp = diff != null && diff! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(child: Text(_dateStr, style: const TextStyle(fontSize: 11, color: AppColors.mutedText))),
          Text(
            '${record.weightKg} kg',
            style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 18, color: AppColors.soil),
          ),
          if (diff != null) ...[
            const SizedBox(width: 8),
            Text(
              isUp ? '+${diff!.toStringAsFixed(1)} ↑' : '${diff!.toStringAsFixed(1)} ↓',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUp ? AppColors.sage : AppColors.rust,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
