import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'dart:math';
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
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scales;

  final _recentScans = const [
    ('Pamuq — TR-2021-0042', '2 dk önce', true),
    ('Karabaş — TR-2020-0018', 'Dün', true),
    ('Sarıkız — TR-2022-0091', '2 gün önce', false),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000),
      )..repeat(reverse: true),
    );

    _scales = List.generate(3, (i) {
      final delay = i * 300;
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.95), weight: 50),
      ]).animate(
        CurvedAnimation(
          parent: _controllers[i],
          curve: Interval(delay / 3000, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleScannedUid(String uid) async {
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
        // navigate to the created sheep profile
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SheepProfileScreen(sheep: res)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kayıt oluşturuldu')));
      }
    }
  }

  Future<void> _simulateNewTag() async {
    // generate a random 6-byte UID like AA:BB:CC:DD:EE:FF
    final rnd = Random();
    final bytes = List<int>.generate(6, (_) => rnd.nextInt(256));
    final uid = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Simule edilen UID: $uid')));
    await _handleScannedUid(uid);
  }

  Future<void> _simulateExistingTag() async {
    final list = await DatabaseHelper.instance.getAllSheep();
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt yok — yeni simule ediyor')),
      );
      await _simulateNewTag();
      return;
    }
    // prefer the first sheep with a non-empty nfcUid
    final s = list.firstWhere(
      (s) => s.nfcUid.isNotEmpty,
      orElse: () => list.first,
    );
    final uid = s.nfcUid.isNotEmpty
        ? s.nfcUid
        : List<int>.generate(6, (_) => Random().nextInt(256))
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(':');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Simule edilen var olan UID: $uid')));
    await _handleScannedUid(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background glows
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x1FE8C97A), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x1A7BAF7A), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          // Animated rings + center icon
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ring 1 (outermost)
                                AnimatedBuilder(
                                  animation: _controllers[0],
                                  builder: (_, __) => Transform.scale(
                                    scale: _scales[0].value,
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.straw.withOpacity(
                                            0.2,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Ring 2
                                AnimatedBuilder(
                                  animation: _controllers[1],
                                  builder: (_, __) => Transform.scale(
                                    scale: _scales[1].value,
                                    child: Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.straw.withOpacity(
                                            0.35,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Ring 3 (innermost)
                                AnimatedBuilder(
                                  animation: _controllers[2],
                                  builder: (_, __) => Transform.scale(
                                    scale: _scales[2].value,
                                    child: Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.straw.withOpacity(
                                            0.6,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Center button - starts NFC session
                                GestureDetector(
                                  onTap: () async {
                                    final available = await NfcManager.instance
                                        .isAvailable();
                                    if (!mounted) return;
                                    if (!available) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('NFC cihazınız desteklemiyor'),
                                        ),
                                      );
                                      return;
                                    }

                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: AppColors.cream,
                                        content: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(color: AppColors.soil),
                                            SizedBox(height: 16),
                                            Text(
                                              'Etiketi telefona yaklaştır...',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: AppColors.soil),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              NfcManager.instance.stopSession();
                                              Navigator.of(c).pop();
                                            },
                                            child: const Text('İptal', style: TextStyle(color: AppColors.soil)),
                                          ),
                                        ],
                                      ),
                                    );

                                    try {
                                      await NfcManager.instance.startSession(
                                        onDiscovered: (tag) async {
                                          final data = tag.data;
                                          dynamic idBytes;

                                          if (data.containsKey('nfca')) {
                                            idBytes = data['nfca']?['identifier'];
                                          }
                                          idBytes ??= data['identifier'];

                                          if (idBytes == null) {
                                            void search(dynamic node) {
                                              if (node is Map) {
                                                node.forEach((k, v) {
                                                  if (idBytes != null) return;
                                                  if (k == 'identifier') {
                                                    idBytes = v;
                                                  } else {
                                                    search(v);
                                                  }
                                                });
                                              }
                                            }
                                            search(data);
                                          }

                                          String? uid;
                                          if (idBytes != null) {
                                            try {
                                              final bytes = idBytes is Iterable
                                                  ? List<int>.from(idBytes)
                                                  : (idBytes as Uint8List).toList();
                                              uid = bytes
                                                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                                                  .join(':');
                                            } catch (_) {
                                              uid = idBytes.toString();
                                            }
                                          }

                                          await NfcManager.instance.stopSession();

                                          if (!mounted) return;
                                          Navigator.of(context).pop(); // dialog'u kapat

                                          if (uid == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Etiket okunamadı')),
                                            );
                                            return;
                                          }

                                          final sheep = await DatabaseHelper.instance.getSheepByNfc(uid);
                                          if (!mounted) return;
                                          if (sheep != null) {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SheepProfileScreen(sheep: sheep),
                                              ),
                                            );
                                          } else {
                                            final res = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddEditSheepScreen(initialNfc: uid!),
                                              ),
                                            );
                                            if (!mounted) return;
                                            if (res is Sheep) {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => SheepProfileScreen(sheep: res),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('NFC hatası: $e')),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.straw,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.straw.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '📡',
                                        style: TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Küpe Tara',
                            style: TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize: 24,
                              color: AppColors.straw,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Telefonu koyunun tasmasındaki\netikete yaklaştır',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF6A5040),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Etiket Simülasyonu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.straw,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fiziksel bir NFC etiketi yoksa bu butonlarla test edebilirsin.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withOpacity(0.75),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      width: min(
                                        MediaQuery.of(context).size.width *
                                            0.45,
                                        220,
                                      ),
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withOpacity(0.04),
                                          side: BorderSide(
                                            color: AppColors.straw.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.add,
                                          color: AppColors.straw,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Yeni Etiket',
                                          style: TextStyle(
                                            color: AppColors.straw,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () async =>
                                            await _simulateNewTag(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: min(
                                        MediaQuery.of(context).size.width *
                                            0.45,
                                        220,
                                      ),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.straw,
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.history,
                                          color: AppColors.soil,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Var Olan Etiket',
                                          style: TextStyle(
                                            color: AppColors.soil,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () async =>
                                            await _simulateExistingTag(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _RecentScansPanel(scans: _recentScans),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dark bottom nav variant
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DarkNavItem(
                      icon: '🏠',
                      label: 'Ana Sayfa',
                      isActive: false,
                      onTap: () => widget.onNavTap(0),
                    ),
                    _DarkNavItem(
                      icon: '🐑',
                      label: 'Sürü',
                      isActive: false,
                      onTap: () => widget.onNavTap(1),
                    ),
                    _DarkNavItem(
                      icon: '📡',
                      label: 'Küpe Tara',
                      isActive: true,
                      onTap: () {},
                    ),
                    _DarkNavItem(
                      icon: '📊',
                      label: 'Raporlar',
                      isActive: false,
                      onTap: () => widget.onNavTap(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScansPanel extends StatelessWidget {
  final List<(String, String, bool)> scans;

  const _RecentScansPanel({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SON TARANANLAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A5040),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...scans.asMap().entries.map((e) {
            final (name, time, isGreen) = e.value;
            final isLast = e.key == scans.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isGreen ? AppColors.sage : AppColors.straw,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6A5040),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(color: Colors.white.withOpacity(0.04), height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DarkNavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DarkNavItem({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.straw.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.straw : const Color(0xFF6A5040),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
