import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../services/database_helper.dart';
import '../models/models.dart';
import 'sheep_profile_screen.dart';
import 'add_edit_sheep_screen.dart';

class NfcScanScreen extends StatefulWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const NfcScanScreen({
    super.key,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final Animation<double> _phoneSlide;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _ring3;
  late final Animation<double> _tagGlow;
  late final Animation<double> _scanBar;
  late final Animation<double> _badge;
  late final Animation<double> _arrowOpacity;

  @override
  void initState() {
    super.initState();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _phoneSlide = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 28),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 36,
      ),
    ]).animate(_loop);

    _ring1 = _makeRing(startFraction: 0.38, endFraction: 0.75);
    _ring2 = _makeRing(startFraction: 0.44, endFraction: 0.80);
    _ring3 = _makeRing(startFraction: 0.50, endFraction: 0.85);

    _tagGlow = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 34),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
    ]).animate(_loop);

    _scanBar = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 6),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 23),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 6),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    ]).animate(_loop);

    _badge = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 14),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_loop);

    _arrowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.5), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 6),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 34),
    ]).animate(_loop);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startNfcSession());
  }

  Animation<double> _makeRing({
    required double startFraction,
    required double endFraction,
  }) {
    final span = endFraction - startFraction;
    return TweenSequence<double>([
      TweenSequenceItem(
          tween: ConstantTween(0.0), weight: startFraction * 100),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: span * 100),
      TweenSequenceItem(
          tween: ConstantTween(0.0), weight: (1.0 - endFraction) * 100),
    ]).animate(_loop);
  }

  @override
  void dispose() {
    _loop.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  String? _extractUid(NfcTag tag) {
    final mifare = MiFareIos.from(tag);
    if (mifare != null) return _bytesToHex(mifare.identifier);

    final iso7816 = Iso7816Ios.from(tag);
    if (iso7816 != null) return _bytesToHex(iso7816.identifier);

    final iso15693 = Iso15693Ios.from(tag);
    if (iso15693 != null) return _bytesToHex(iso15693.identifier);

    return null;
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  Future<void> _startNfcSession() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) return;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        alertMessageIos: 'Etiketi telefonun üst kısmına (kamera tarafına) yaklaştır',
        invalidateAfterFirstReadIos: true,
        onSessionErrorIos: (error) {
          if (!mounted) return;
          final isCancelled =
              error.code == NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout ||
              error.code == NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled;
          if (!isCancelled) {
            showAppNotification(context, 'NFC hatası: ${error.message}', isError: true);
          }
        },
        onDiscovered: (tag) => _handleTag(tag),
      );
    } catch (e) {
      if (!mounted) return;
      showAppNotification(context, 'NFC hatası: $e', isError: true);
    }
  }

  Future<void> _handleTag(NfcTag tag) async {
    final uid = _extractUid(tag);
    await NfcManager.instance.stopSession();
    if (!mounted) return;

    if (uid == null) {
      showAppNotification(context, 'Etiket okunamadı', isError: true);
      _startNfcSession();
      return;
    }

    final sheep = await DatabaseHelper.instance.getSheepByNfc(uid);
    if (!mounted) return;
    if (sheep != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SheepProfileScreen(sheep: sheep)),
      );
    } else {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditSheepScreen(initialNfc: uid)),
      );
      if (!mounted) return;
      if (res is Sheep) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SheepProfileScreen(sheep: res)),
        );
      }
    }

    if (mounted) _startNfcSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _startNfcSession,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context2, child) => CustomPaint(
                          painter: _LambCollarPainter(
                            phoneSlide: _phoneSlide.value,
                            ring1: _ring1.value,
                            ring2: _ring2.value,
                            ring3: _ring3.value,
                            tagGlow: _tagGlow.value,
                            scanBar: _scanBar.value,
                            badge: _badge.value,
                            arrowOpacity: _arrowOpacity.value,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Telefonu tasmaya yaklaştır',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _BottomNav(navIndex: widget.navIndex, onNavTap: widget.onNavTap),
        ],
      ),
    );
  }
}

// ── CustomPainter — kuzu + tasma + telefon animasyonu ────────────────────────
class _LambCollarPainter extends CustomPainter {
  final double phoneSlide;
  final double ring1;
  final double ring2;
  final double ring3;
  final double tagGlow;
  final double scanBar;
  final double badge;
  final double arrowOpacity;

  _LambCollarPainter({
    required this.phoneSlide,
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.tagGlow,
    required this.scanBar,
    required this.badge,
    required this.arrowOpacity,
  });

  late double _sx;
  late double _sy;
  late double _ox;
  late double _oy;

  Offset _p(double x, double y) => Offset(_ox + x * _sx, _oy + y * _sy);
  double _s(double v) => v * _sx;
  double _sv(double v) => v * _sy;

  @override
  void paint(Canvas canvas, Size size) {
    const vbW = 680.0;
    const vbH = 500.0;
    final scale = math.min(size.width / vbW, size.height / vbH);
    _sx = scale;
    _sy = scale;
    _ox = (size.width - vbW * scale) / 2;
    _oy = (size.height - vbH * scale) / 2;

    _drawBackground(canvas, size);
    _drawGround(canvas);
    _drawBodyWool(canvas);
    _drawLegs(canvas);
    _drawNeck(canvas);
    _drawCollar(canvas);
    _drawHead(canvas);
    _drawEars(canvas);
    _drawFace(canvas);
    _drawNfcTag(canvas);
    _drawSignalRings(canvas);
    _drawPhone(canvas);
    _drawArrow(canvas);
    _drawBadge(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.wool,
    );
  }

  void _drawGround(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: _p(310, 462), width: _s(320), height: _sv(26)),
      Paint()..color = const Color(0xFFD4C8A8).withValues(alpha: 0.4),
    );
  }

  void _drawBodyWool(Canvas canvas) {
    final base = Paint()..color = const Color(0xFFEDE5D2);
    canvas.drawOval(
      Rect.fromCenter(
          center: _p(310, 420), width: _s(236), height: _sv(104)),
      base,
    );
    final wool =
        Paint()..color = const Color(0xFFFAF4E8).withValues(alpha: 0.85);
    for (final blob in [
      (_p(222, 408), _s(60.0)),
      (_p(255, 395), _s(52.0)),
      (_p(288, 390), _s(48.0)),
      (_p(320, 388), _s(48.0)),
      (_p(352, 392), _s(48.0)),
      (_p(382, 404), _s(52.0)),
      (_p(405, 418), _s(44.0)),
      (_p(215, 430), _s(44.0)),
      (_p(400, 432), _s(40.0)),
    ]) {
      canvas.drawCircle(blob.$1, blob.$2 / 2, wool);
    }
  }

  void _drawLegs(Canvas canvas) {
    final legPaint = Paint()..color = const Color(0xFFD4C4A0);
    final hoofPaint = Paint()..color = const Color(0xFF8C7A5A);
    for (final leg in [
      (180.0, 398.0),
      (205.0, 402.0),
      (258.0, 400.0),
      (283.0, 404.0),
    ]) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_p(leg.$1, leg.$2).dx, _p(leg.$1, leg.$2).dy,
            _s(16), _sv(36)),
        Radius.circular(_s(8)),
      );
      canvas.drawRRect(rect, legPaint);
      final hoofRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_p(leg.$1, leg.$2 + 30).dx,
            _p(leg.$1, leg.$2 + 30).dy, _s(16), _sv(7)),
        Radius.circular(_s(3)),
      );
      canvas.drawRRect(hoofRect, hoofPaint);
    }
  }

  void _drawNeck(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE8DEC8);
    canvas.save();
    canvas.translate(_p(318, 330).dx, _p(318, 330).dy);
    canvas.rotate(-12 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _s(68), height: _sv(100)),
      paint,
    );
    canvas.restore();
  }

  void _drawCollar(Canvas canvas) {
    _drawCollarArc(canvas, const Color(0xFF4A2E10), 18, 348.0);
    _drawCollarArc(canvas, const Color(0xFF5C3D1E), 16, 336.0);
    _drawCollarArc(canvas, const Color(0xFF6B4828), 12, 342.0);
    _drawCollarArcHighlight(canvas);
    _drawBuckle(canvas);
  }

  void _drawCollarArc(
      Canvas canvas, Color color, double strokeWidth, double y) {
    final path = Path();
    path.moveTo(_p(238, y).dx, _p(238, y).dy);
    path.quadraticBezierTo(
      _p(310, y + 14).dx, _p(310, y + 14).dy,
      _p(382, y).dx, _p(382, y).dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sv(strokeWidth)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCollarArcHighlight(Canvas canvas) {
    final path = Path();
    path.moveTo(_p(248, 340).dx, _p(248, 340).dy);
    path.quadraticBezierTo(
      _p(310, 351).dx, _p(310, 351).dy,
      _p(372, 340).dx, _p(372, 340).dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8C6A3A).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sv(3)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBuckle(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(368, 335).dx, _p(368, 335).dy, _s(18), _sv(18)),
        Radius.circular(_s(4)),
      ),
      Paint()..color = const Color(0xFF3A2510),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(371, 338).dx, _p(371, 338).dy, _s(12), _sv(12)),
        Radius.circular(_s(2)),
      ),
      Paint()..color = const Color(0xFF2C1A0E),
    );
  }

  void _drawNfcTag(Canvas canvas) {
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          _p(289, 346).dx, _p(289, 346).dy, _s(42), _sv(22)),
      Radius.circular(_s(6)),
    );
    canvas.drawRRect(tagRect, Paint()..color = const Color(0xFFD4A843));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(293, 350).dx, _p(293, 350).dy, _s(34), _sv(14)),
        Radius.circular(_s(3)),
      ),
      Paint()..color = const Color(0xFF2C1A0E).withValues(alpha: 0.3),
    );

    final antennaPaint = Paint()
      ..color = const Color(0xFFE8C97A).withValues(alpha: 0.75)
      ..strokeWidth = _sv(1);
    for (final dy in [353.0, 356.0, 359.0]) {
      canvas.drawLine(_p(295, dy), _p(325, dy), antennaPaint);
    }

    if (tagGlow > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              _p(285, 342).dx, _p(285, 342).dy, _s(50), _sv(30)),
          Radius.circular(_s(8)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _sv(2.2)
          ..color = const Color(0xFFE8C97A).withValues(alpha: tagGlow),
      );
    }
  }

  Offset get _tagCenter => _p(310, 357);

  void _drawSignalRings(Canvas canvas) {
    _drawRing(canvas, ring1, 20, 2.5);
    _drawRing(canvas, ring2, 32, 2.0);
    _drawRing(canvas, ring3, 46, 1.5);
  }

  void _drawRing(
      Canvas canvas, double t, double baseRadius, double strokeWidth) {
    if (t <= 0) return;
    final radius = _s(baseRadius) + _s(baseRadius * 0.7) * t;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.9;
    canvas.drawCircle(
      _tagCenter,
      radius,
      Paint()
        ..color = AppColors.sage.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sv(strokeWidth),
    );
  }

  void _drawHead(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
          center: _p(310, 242), width: _s(164), height: _sv(152)),
      Paint()..color = const Color(0xFFEDE5D2),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: _p(310, 295), width: _s(104), height: _sv(60)),
      Paint()..color = const Color(0xFFE2D6BC),
    );
    final wool = Paint()..color = const Color(0xFFFAF4E8);
    for (final blob in [
      (_p(268, 200), _s(56.0)),
      (_p(295, 188), _s(52.0)),
      (_p(324, 188), _s(52.0)),
      (_p(350, 200), _s(52.0)),
    ]) {
      canvas.drawCircle(blob.$1, blob.$2 / 2, wool);
    }
  }

  void _drawEars(Canvas canvas) {
    const earColor = Color(0xFFE2D4B8);
    const innerEarColor = Color(0xFFD0C0A0);

    canvas.save();
    canvas.translate(_p(228, 248).dx, _p(228, 248).dy);
    canvas.rotate(-15 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _s(36), height: _sv(60)),
      Paint()..color = earColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _s(20), height: _sv(38)),
      Paint()..color = innerEarColor.withValues(alpha: 0.55),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(_p(392, 248).dx, _p(392, 248).dy);
    canvas.rotate(15 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _s(36), height: _sv(60)),
      Paint()..color = earColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _s(20), height: _sv(38)),
      Paint()..color = innerEarColor.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    for (final ex in [272.0, 348.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: _p(ex, 248), width: _s(24), height: _sv(22)),
        Paint()..color = const Color(0xFF3D2810),
      );
      canvas.drawCircle(
          _p(ex, 248), _s(6), Paint()..color = const Color(0xFF1A0E06));
      canvas.drawCircle(
        _p(ex + 3, 245),
        _s(3),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    for (final nx in [298.0, 322.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: _p(nx, 300), width: _s(20), height: _sv(14)),
        Paint()..color = const Color(0xFFC8A882),
      );
      canvas.drawOval(
        Rect.fromCenter(center: _p(nx - 4, 299), width: _s(8), height: _sv(6)),
        Paint()..color = const Color(0xFF9A7258).withValues(alpha: 0.6),
      );
      canvas.drawOval(
        Rect.fromCenter(center: _p(nx + 4, 300), width: _s(8), height: _sv(6)),
        Paint()..color = const Color(0xFF9A7258).withValues(alpha: 0.6),
      );
    }

    final mouthPath = Path();
    mouthPath.moveTo(_p(295, 312).dx, _p(295, 312).dy);
    mouthPath.quadraticBezierTo(
      _p(310, 322).dx, _p(310, 322).dy,
      _p(325, 312).dx, _p(325, 312).dy,
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFFA07858)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sv(1.6)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPhone(Canvas canvas) {
    final slideOffset = -phoneSlide * _s(72);

    canvas.save();
    canvas.translate(slideOffset, 0);

    canvas.drawOval(
      Rect.fromCenter(
          center: _p(510, 410), width: _s(64), height: _sv(14)),
      Paint()..color = AppColors.soil.withValues(alpha: 0.12),
    );

    canvas.save();
    final pivotX = _p(500, 356).dx;
    final pivotY = _p(500, 356).dy;
    canvas.translate(pivotX, pivotY);
    canvas.rotate(-8 * math.pi / 180);
    canvas.translate(-pivotX, -pivotY);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(462, 306).dx, _p(462, 306).dy, _s(76), _sv(130)),
        Radius.circular(_s(13)),
      ),
      Paint()..color = AppColors.soil,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(467, 314).dx, _p(467, 314).dy, _s(66), _sv(114)),
        Radius.circular(_s(10)),
      ),
      Paint()..color = const Color(0xFF1A0E06),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(470, 317).dx, _p(470, 317).dy, _s(60), _sv(108)),
        Radius.circular(_s(8)),
      ),
      Paint()..color = const Color(0xFFE8DEC8).withValues(alpha: 0.05),
    );

    _drawScreenArcs(canvas);

    if (scanBar > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              _p(470, 358).dx, _p(470, 358).dy, _s(60), _sv(2)),
          Radius.circular(_s(1)),
        ),
        Paint()..color = AppColors.sage.withValues(alpha: scanBar * 0.85),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(477, 310).dx, _p(477, 310).dy, _s(26), _sv(6)),
        Radius.circular(_s(3)),
      ),
      Paint()..color = const Color(0xFF1A0E06),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(484, 428).dx, _p(484, 428).dy, _s(18), _sv(4)),
        Radius.circular(_s(2)),
      ),
      Paint()..color = const Color(0xFF3A2510),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(461, 335).dx, _p(461, 335).dy, _s(3), _sv(24)),
        Radius.circular(_s(1.5)),
      ),
      Paint()..color = const Color(0xFF3A2510),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(459, 350).dx, _p(459, 350).dy, _s(4), _sv(16)),
        Radius.circular(_s(2)),
      ),
      Paint()..color = const Color(0xFFE8C97A).withValues(alpha: 0.55),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(462, 320).dx, _p(462, 320).dy, _s(2), _sv(28)),
        Radius.circular(_s(1)),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    canvas.restore();
    canvas.restore();
  }

  void _drawScreenArcs(Canvas canvas) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sv(1.8)
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(_p(487, 372).dx, _p(487, 372).dy);
    path1.quadraticBezierTo(
        _p(500, 360).dx, _p(500, 360).dy,
        _p(513, 372).dx, _p(513, 372).dy);
    canvas.drawPath(
        path1,
        arcPaint
          ..color = const Color(0xFFE8C97A).withValues(alpha: 0.5));

    final path2 = Path();
    path2.moveTo(_p(482, 378).dx, _p(482, 378).dy);
    path2.quadraticBezierTo(
        _p(500, 362).dx, _p(500, 362).dy,
        _p(518, 378).dx, _p(518, 378).dy);
    canvas.drawPath(
        path2,
        arcPaint
          ..color = const Color(0xFFE8C97A).withValues(alpha: 0.32));

    canvas.drawCircle(_p(500, 378), _s(3.5),
        Paint()..color = const Color(0xFFE8C97A).withValues(alpha: 0.65));
  }

  void _drawArrow(Canvas canvas) {
    if (arrowOpacity <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFFC4B090).withValues(alpha: arrowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sv(1.4)
      ..strokeCap = StrokeCap.round;

    final start = _p(455, 348);
    final end = _p(405, 354);
    const dashLen = 5.0;
    const gapLen = 5.0;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double drawn = 0;
    bool drawing = true;
    while (drawn < total) {
      final segLen = drawing
          ? math.min(dashLen * _sx, total - drawn)
          : math.min(gapLen * _sx, total - drawn);
      if (drawing) {
        canvas.drawLine(
          start + dir * drawn,
          start + dir * (drawn + segLen),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }

    final arrowTip = _p(405, 354);
    final arrowPath = Path();
    arrowPath.moveTo(arrowTip.dx + _s(9), arrowTip.dy - _sv(4));
    arrowPath.lineTo(arrowTip.dx, arrowTip.dy);
    arrowPath.lineTo(arrowTip.dx + _s(9), arrowTip.dy + _sv(4));
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFFC4B090).withValues(alpha: arrowOpacity)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawBadge(Canvas canvas) {
    if (badge <= 0) return;
    final scale = badge.clamp(0.0, 1.0);
    final center = _p(310, 468);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _p(220, 458).dx, _p(220, 458).dy, _s(180), _sv(28)),
        Radius.circular(_sv(14)),
      ),
      Paint()..color = AppColors.soil,
    );

    canvas.drawCircle(
        _p(240, 472), _s(9), Paint()..color = AppColors.sage);

    final checkPath = Path();
    checkPath.moveTo(_p(235, 472).dx, _p(235, 472).dy);
    checkPath.lineTo(_p(239, 476).dx, _p(239, 476).dy);
    checkPath.lineTo(_p(246, 468).dx, _p(246, 468).dy);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sv(2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LambCollarPainter old) => true;
}

// ── Alt navigasyon ────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const _BottomNav({required this.navIndex, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x0F000000))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(icon: '🏠', label: 'Ana Sayfa', isActive: navIndex == 0,
                  onTap: () => onNavTap(0)),
              _NavBtn(icon: '🐑', label: 'Sürü', isActive: navIndex == 1,
                  onTap: () => onNavTap(1)),
              _NavBtn(icon: '🏷️', label: 'Tara', isActive: navIndex == 2,
                  onTap: () => onNavTap(2)),
              _NavBtn(icon: '📊', label: 'Raporlar', isActive: navIndex == 3,
                  onTap: () => onNavTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.soil.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.soil : AppColors.mutedText,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
