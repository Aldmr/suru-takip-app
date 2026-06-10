import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class BackupEntry {
  final String path;
  final String name;
  final DateTime? createdAt;

  const BackupEntry({
    required this.path,
    required this.name,
    this.createdAt,
  });

  String get displayName {
    // backup_2026-06-04T10-30-00-000Z.json → 04.06.2026 10:30
    try {
      final raw = name
          .replaceFirst('backup_', '')
          .replaceFirst('.json', '')
          .replaceAll('-', ':')
          .replaceFirst('T', ' ');
      // Reconstruct ISO format: 2026:06:04 10:30:00:000Z
      final parts = raw.split(' ');
      final dateParts = parts[0].split(':');
      final date = '${dateParts[0]}-${dateParts[1]}-${dateParts[2]}';
      final timeParts = parts[1].split(':');
      final time = '${timeParts[0]}:${timeParts[1]}';
      final dt = DateTime.tryParse('${date}T$time');
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    if (createdAt != null) {
      final d = createdAt!.toLocal();
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return name;
  }
}

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const _bucket = 'backups';

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> backup() async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Giriş yapılmamış');

    final data = await DatabaseHelper.instance.exportAllData();
    final bytes = utf8.encode(jsonEncode(data));

    final now = DateTime.now().toUtc();
    final ts =
        '${now.year}-${_p(now.month)}-${_p(now.day)}T${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}-000Z';
    final path = '$uid/backup_$ts.json';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/json'),
        );
  }

  Future<List<BackupEntry>> listBackups() async {
    final uid = currentUser?.id;
    if (uid == null) return [];

    final files = await _client.storage.from(_bucket).list(path: uid);
    final entries = files
        .where((f) => f.name.endsWith('.json'))
        .map((f) => BackupEntry(
              path: '$uid/${f.name}',
              name: f.name,
              createdAt:
                  f.createdAt != null ? DateTime.tryParse(f.createdAt!) : null,
            ))
        .toList();

    entries.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return entries;
  }

  Future<void> restore(String path) async {
    final bytes = await _client.storage.from(_bucket).download(path);
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    await DatabaseHelper.instance.importAllData(data);
  }

  Future<void> deleteBackup(String path) async {
    await _client.storage.from(_bucket).remove([path]);
  }

  String _p(int v) => v.toString().padLeft(2, '0');
}
