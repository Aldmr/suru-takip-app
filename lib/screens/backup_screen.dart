import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  List<BackupEntry> _backups = [];
  String? _error;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _isSignedIn = SupabaseService.instance.isSignedIn;
    _userEmail = SupabaseService.instance.currentUser?.email;
    if (_isSignedIn) _loadBackups();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SupabaseService.instance.listBackups();
      if (!mounted) return;
      setState(() => _backups = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.signIn(email, pass);
      if (!mounted) return;
      setState(() {
        _isSignedIn = true;
        _userEmail = SupabaseService.instance.currentUser?.email;
      });
      _loadBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Giriş hatası: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.signUp(email, pass);
      if (!mounted) return;
      _showInfo('Kayıt başarılı! E-posta onayı gerekiyorsa gelen kutunuzu kontrol edin.');
      setState(() {
        _isSignedIn = SupabaseService.instance.isSignedIn;
        _userEmail = SupabaseService.instance.currentUser?.email;
      });
      if (_isSignedIn) _loadBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Kayıt hatası: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.instance.signOut();
    if (!mounted) return;
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
      _backups = [];
    });
  }

  Future<void> _doBackup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.backup();
      if (!mounted) return;
      _showInfo('Yedekleme tamamlandı');
      _loadBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Yedekleme hatası: ${_friendlyError(e)}');
      setState(() => _loading = false);
    }
  }

  Future<void> _doRestore(BackupEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.wool,
        title: const Text('Geri Yükle?',
            style: TextStyle(fontFamily: 'DMSerifDisplay', color: AppColors.soil)),
        content: Text(
          '${entry.displayName} tarihli yedek geri yüklenecek.\nMevcut tüm veriler silinerek yedekteki verilerle değiştirilecek.',
          style: const TextStyle(color: AppColors.bark),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.soil,
                foregroundColor: AppColors.straw),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.restore(entry.path);
      if (!mounted) return;
      _showInfo('Geri yükleme tamamlandı. Uygulamayı yeniden başlatın.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Geri yükleme hatası: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doDelete(BackupEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.wool,
        title: const Text('Yedeği Sil?',
            style: TextStyle(fontFamily: 'DMSerifDisplay', color: AppColors.soil)),
        content: Text(
          '${entry.displayName} tarihli yedek kalıcı olarak silinecek.',
          style: const TextStyle(color: AppColors.bark),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await SupabaseService.instance.deleteBackup(entry.path);
      if (!mounted) return;
      _loadBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Silme hatası: ${_friendlyError(e)}';
        _loading = false;
      });
    }
  }

  void _showInfo(String msg) {
    showAppNotification(context, msg);
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login credentials')) return 'E-posta veya şifre hatalı';
    if (s.contains('Email not confirmed')) return 'E-posta onayı bekleniyor';
    if (s.contains('User already registered')) return 'Bu e-posta zaten kayıtlı';
    if (s.contains('network') || s.contains('SocketException')) {
      return 'İnternet bağlantısı yok';
    }
    return s.length > 80 ? '${s.substring(0, 80)}…' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wool,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isSignedIn ? _buildSignedInBody() : _buildAuthBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: const BoxDecoration(
          color: AppColors.soil,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.straw, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Text('☁️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bulut Yedekleme',
                style: TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 22,
                  color: AppColors.straw,
                ),
              ),
            ),
            if (_isSignedIn)
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.straw),
                tooltip: 'Çıkış Yap',
                onPressed: _signOut,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Giriş Yap / Kayıt Ol',
                  style: TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 18,
                    color: AppColors.soil,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verilerinizi güvenle yedeklemek için hesabınıza giriş yapın.',
                  style: TextStyle(fontSize: 13, color: AppColors.bark),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 18),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.soil,
                              foregroundColor: AppColors.straw,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _signIn,
                            child: const Text('Giriş Yap', style: TextStyle(fontSize: 15)),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.soil,
                              side: const BorderSide(color: AppColors.soil),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _signUp,
                            child: const Text('Yeni Hesap Oluştur', style: TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInBody() {
    return RefreshIndicator(
      onRefresh: _loadBackups,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            // Kullanıcı bilgisi + yedekleme butonu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, color: AppColors.soil),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _userEmail ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.soil,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Şimdi Yedekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.soil,
                              foregroundColor: AppColors.straw,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _doBackup,
                          ),
                        ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                'YEDEKLER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bark,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            if (_backups.isEmpty && !_loading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.bark),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz yedek yok',
                      style: TextStyle(color: AppColors.bark, fontSize: 15),
                    ),
                  ],
                ),
              ),

            ..._backups.map((entry) => _BackupTile(
                  entry: entry,
                  onRestore: () => _doRestore(entry),
                  onDelete: () => _doDelete(entry),
                )),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupEntry entry;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupTile({
    required this.entry,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: AppColors.sage, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.soil,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onRestore,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.soil,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Yükle', style: TextStyle(fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
