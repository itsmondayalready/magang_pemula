import 'package:supabase_flutter/supabase_flutter.dart';

class LoginLogEntry {
  final String id;
  final String userId;
  final String role;
  final String? email;
  final String? guestName;
  final DateTime createdAt;

  const LoginLogEntry({
    required this.id,
    required this.userId,
    required this.role,
    this.email,
    this.guestName,
    required this.createdAt,
  });
}

class LoginLogRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logLogin({
    required String userId,
    required String role,
    String? email,
    String? guestName,
  }) async {
    final payload = {
      'user_id': userId,
      'role': role,
      'email': email,
      'guest_name': guestName,
      // created_at otomatis pakai default now() dari database
    };
    await _supabase.from('login_logs').insert(payload);
  }

  Future<List<LoginLogEntry>> fetchRecent({int limit = 50}) async {
    final response = await _supabase
        .from('login_logs')
        .select('id,user_id,role,email,guest_name,created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = response as List<dynamic>;

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => LoginLogEntry(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            role: row['role'] as String,
            email: row['email'] as String?,
            guestName: row['guest_name'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> deleteLog(String logId) async {
    await _supabase.from('login_logs').delete().eq('id', logId);
  }
}
