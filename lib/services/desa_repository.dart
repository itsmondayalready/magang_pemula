import 'package:supabase_flutter/supabase_flutter.dart';

class DesaRepository {
  final SupabaseClient _db = Supabase.instance.client;

  // List desa ringan untuk picker/list-card
  // Menggunakan v_desa_list jika tersedia; jika tidak, fallback ke desa saja.
  Future<List<Map<String, dynamic>>> fetchDesaList({String? search, int limit = 20, int offset = 0}) async {
    final tablesToTry = <String>['v_desa_list', 'desa'];
    for (final table in tablesToTry) {
      try {
        var query = _db.from(table).select();
        if (search != null && search.trim().isNotEmpty) {
          final s = search.trim();
          // Sederhanakan: cari di nama saja agar kompatibel
          query = query.ilike('nama', '%$s%');
        }
        final rows = await query.order('nama').range(offset, offset + limit - 1);
        return List<Map<String, dynamic>>.from(rows);
      } catch (_) {
        // coba table berikutnya
      }
    }
    return [];
  }

  // Detail desa + profile (1:1)
  Future<Map<String, dynamic>?> fetchDesaDetailByKode(String kodeWilayah) async {
    try {
      final row = await _db
          .from('desa')
          .select('*, desa_profile(*)')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (e) {
      return null;
    }
  }

  // Ringkasan kependudukan terbaru berdasarkan kode_wilayah
  // Prefer v_kependudukan_latest + join desa, fallback query langsung ke kependudukan inner join desa
  Future<Map<String, dynamic>?> fetchLatestKependudukanByKode(String kodeWilayah) async {
    // 1) Coba view latest
    try {
      final List withJoin = await _db
          .from('kependudukan')
          .select('total_penduduk,total_kk,laki_laki,perempuan,periode_date,tahun,bulan, desa!inner(kode_wilayah)')
          .eq('desa.kode_wilayah', kodeWilayah)
          .order('periode_date', ascending: false)
          .limit(1);
      if (withJoin.isNotEmpty) {
        return Map<String, dynamic>.from(withJoin.first);
      }
    } catch (_) {}

    // 2) Fallback pakai dua langkah: ambil desa.id lalu query kependudukan
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) return null;
      final desaId = desa['id'] as String;
    final List rows = await _db
          .from('kependudukan')
          .select()
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
    if (rows.isNotEmpty) return Map<String, dynamic>.from(rows.first);
    } catch (_) {}

    return null;
  }

  // Aparatur desa berdasarkan kode_wilayah
  // Urutkan terutama berdasarkan 'urutan' jika ada, lalu created_at sebagai tie-breaker
  Future<List<Map<String, dynamic>>> fetchAparaturByKode(String kodeWilayah) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) return [];
      final desaId = desa['id'] as String;
      final List rows = await _db
          .from('aparatur_desa')
          .select()
          .eq('desa_id', desaId)
          .order('urutan', ascending: true)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  // Ambil satu desa default 'terbaru' berdasarkan beberapa kemungkinan kolom waktu/id.
  // Urutan prioritas: updated_at desc -> created_at desc -> id desc -> nama asc.
  Future<Map<String, dynamic>?> fetchDefaultDesa() async {
    final tablesToTry = <String>['v_desa_list', 'desa'];
    final orderCandidates = <Map<String, dynamic>>[
      {'col': 'updated_at', 'asc': false},
      {'col': 'created_at', 'asc': false},
      {'col': 'id', 'asc': false},
      {'col': 'nama', 'asc': true},
    ];
    for (final table in tablesToTry) {
      for (final cand in orderCandidates) {
        try {
          final List rows = await _db
              .from(table)
              .select()
              .order(cand['col'] as String, ascending: cand['asc'] as bool)
              .limit(1);
          if (rows.isNotEmpty) {
            return Map<String, dynamic>.from(rows.first);
          }
        } catch (_) {
          // coba kandidat/kolom berikutnya atau table berikutnya
        }
      }
    }
    return null;
  }
}
