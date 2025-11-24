import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all desa rows from `desa_dropdown` table and return a map
  /// grouped by kecamatan: { kecamatan: [ { 'desa': nama, 'kode': kode }, ... ] }
  static Future<Map<String, List<Map<String, String>>>> fetchAllDesaDropdown() async {
    final Map<String, List<Map<String, String>>> byKec = {};
    // Select all columns and normalize keys to lowercase so the code is
    // tolerant to column name casing (e.g. `Kecamatan` vs `kecamatan`) which
    // can happen if the table was created/imported with quoted headers.
    final res = await _client.from('desa_dropdown').select('*');
    // handle both supabase client styles: some versions return a
    // PostgrestResponse-like object (with `.data` and `.error`) while
    // others return the data as a plain List directly. Cope with both.
    final result = (res is PostgrestTransformBuilder) ? await (res as dynamic).execute() : res;
    // extract an error message if present without assuming the shape
    String? errorMsg;
    try {
      errorMsg = (result.error != null) ? result.error!.message as String? : null;
    } catch (_) {
      try {
        if (result is Map && result.containsKey('error')) errorMsg = result['error']?.toString();
      } catch (_) {}
    }
    if (errorMsg != null && errorMsg.isNotEmpty) throw Exception('Supabase error: $errorMsg');

    List<dynamic> data;
    try {
      data = (result.data as List<dynamic>?) ?? [];
    } catch (_) {
      if (result is List) {
        data = result;
      } else if (result is Map && result.containsKey('data')) {
        data = (result['data'] as List<dynamic>?) ?? [];
      } else {
        throw Exception('Unexpected Supabase response shape: $result');
      }
    }
    // Build list then sort by kecamatan client-side for predictable order
    final List<Map<String, dynamic>> rows = [];
    for (final row in data) {
      final r = row as Map<String, dynamic>;
      // normalize keys to lowercase and replace non-alphanumeric characters
      // with underscores so headers like "Kode Wilayah" or "Kode-Wilayah"
      // become `kode_wilayah` and can be looked up reliably.
      final Map<String, dynamic> nr = {};
      String normKey(Object? key) => key.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      r.forEach((k, v) {
        nr[normKey(k)] = v;
      });
      final String kec = (nr['kecamatan'] ?? '').toString().trim();
      final String kode = (nr['kode_wilayah'] ?? nr['kode'] ?? '').toString().trim();
      final String desa = (nr['desa'] ?? nr['nama'] ?? '').toString().trim();
      if (kec.isEmpty || kode.isEmpty || desa.isEmpty) continue;
      rows.add({'kecamatan': kec, 'kode': kode, 'desa': desa});
    }
    rows.sort((a, b) => a['kecamatan'].toString().toLowerCase().compareTo(b['kecamatan'].toString().toLowerCase()));
    for (final r in rows) {
      final kec = r['kecamatan'] as String;
      final kode = r['kode'] as String;
      final desa = r['desa'] as String;
      byKec.putIfAbsent(kec, () => []).add({'desa': desa, 'kode': kode});
    }

    return byKec;
  }

  /// Fetch desa list for a specific kecamatan
  static Future<List<Map<String, String>>> fetchDesaForKecamatan(String kecamatan) async {
    // Fetch all rows and filter client-side using normalized keys. This
    // avoids errors when column names differ in casing from the queries.
    final res = await _client.from('desa_dropdown').select('*');
    final result = (res is PostgrestTransformBuilder) ? await (res as dynamic).execute() : res;
    String? errorMsg;
    try {
      errorMsg = (result.error != null) ? result.error!.message as String? : null;
    } catch (_) {
      try {
        if (result is Map && result.containsKey('error')) errorMsg = result['error']?.toString();
      } catch (_) {}
    }
    if (errorMsg != null && errorMsg.isNotEmpty) throw Exception('Supabase error: $errorMsg');

    List<dynamic> data;
    try {
      data = (result.data as List<dynamic>?) ?? [];
    } catch (_) {
      if (result is List) {
        data = result;
      } else if (result is Map && result.containsKey('data')) {
        data = (result['data'] as List<dynamic>?) ?? [];
      } else {
        throw Exception('Unexpected Supabase response shape: $result');
      }
    }
    final List<Map<String, String>> out = [];
    for (final r0 in data) {
      final row = r0 as Map<String, dynamic>;
      final Map<String, dynamic> nr = {};
      String normKey(Object? key) => key.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      row.forEach((k, v) {
        nr[normKey(k)] = v;
      });
      final kec = (nr['kecamatan'] ?? '').toString();
      if (kec.toLowerCase() != kecamatan.toLowerCase()) continue;
      final kode = (nr['kode_wilayah'] ?? nr['kode'] ?? '').toString();
      final desa = (nr['desa'] ?? nr['nama'] ?? '').toString();
      if (kode.isEmpty || desa.isEmpty) continue;
      out.add({'kode': kode, 'desa': desa});
    }
    out.sort((a, b) => a['desa']!.toLowerCase().compareTo(b['desa']!.toLowerCase()));
    return out;
  }
}
