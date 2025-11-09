import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository sederhana untuk membaca catatan (notes) per domain/section.
///
/// Skema tabel yang diasumsikan (lihat DDL di jawaban):
///   public.catatan(
///     id uuid pk,
///     desa_id uuid fk, kode_wilayah varchar(10) fk,
///     year int not null,
///     domain text/enum,            -- gunakan nilai 'pendidikan'
///     section text not null,       -- 'negeri' | 'swasta' | 'lb_keagamaan_keterampilan'
///     title text not null,
///     paras jsonb not null,        -- array of paragraphs, contoh: ["Kalimat 1", "Kalimat 2"]
///     created_at, updated_at, created_by
///   )
class NotesRepository {
  final SupabaseClient _db = Supabase.instance.client;
  int _defaultYear() => DateTime.now().year;

  /// Ambil catatan pendidikan untuk kode wilayah + tahun.
  /// Prioritas baca dari tabel khusus `pendidikan_catatan`.
  /// Fallback ke tabel generik `catatan` (dengan domain = 'pendidikan') bila tabel khusus tidak ada.
  /// Hasil: List of maps dengan keys: section, title, paras (`List<String>`).
  Future<List<Map<String, dynamic>>> getPendidikanNotes(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      // Coba tabel khusus lebih dulu
      final rows = await _db
          .from('pendidikan_catatan')
          .select('section, title, paras')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('section');
      return rows
          .map<Map<String, dynamic>>(
            (r) => {
              'section': r['section'] as String,
              'title': r['title'] as String,
              'paras':
                  (r['paras'] as List?)
                      ?.cast<dynamic>()
                      .map((e) => e.toString())
                      .toList() ??
                  <String>[],
            },
          )
          .toList();
    } on PostgrestException catch (e) {
      // Tabel tidak ditemukan -> fallback ke tabel generik `catatan`
      // PGRST205: could not find table in schema cache
      if (e.code == 'PGRST205' ||
          (e.message.toLowerCase().contains('could not find the table') &&
              e.message.toLowerCase().contains('pendidikan_catatan'))) {
        try {
          final rows = await _db
              .from('catatan')
              .select('section, title, paras')
              .eq('kode_wilayah', kodeWilayah)
              .eq('year', y)
              .eq('domain', 'pendidikan')
              .order('section');
          return rows
              .map<Map<String, dynamic>>(
                (r) => {
                  'section': r['section'] as String,
                  'title': r['title'] as String,
                  'paras':
                      (r['paras'] as List?)
                          ?.cast<dynamic>()
                          .map((e) => e.toString())
                          .toList() ??
                      <String>[],
                },
              )
              .toList();
        } on PostgrestException {
          // Kedua tabel tidak ada atau akses ditolak -> kembalikan kosong
          return <Map<String, dynamic>>[];
        }
      }
      rethrow; // error lain, biarkan caller menangani
    }
  }

  /// Upsert catatan pendidikan untuk satu section.
  ///
  /// Prefer menggunakan tabel khusus `pendidikan_catatan` dengan onConflict (desa_id, year, section),
  /// fallback ke tabel generik `catatan` (domain='pendidikan') dengan onConflict (desa_id, year, domain, section)
  /// bila tabel khusus tidak tersedia.
  Future<void> upsertPendidikanNote({
    required String kodeWilayah,
    required String desaId,
    int? year,
    required String
    section, // 'negeri' | 'swasta' | 'lb_keagamaan_keterampilan'
    required String title,
    required List<String> paras,
  }) async {
    final y = year ?? _defaultYear();
    final now = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'kode_wilayah': kodeWilayah,
      'desa_id': desaId,
      'year': y,
      'section': section,
      'title': title,
      'paras': paras,
      'updated_at': now,
    };

    try {
      // Coba tabel khusus terlebih dahulu
      await _db
          .from('pendidikan_catatan')
          .upsert(payload, onConflict: 'desa_id,year,section')
          .select()
          .maybeSingle();
      return;
    } on PostgrestException catch (e) {
      // Fallback jika tabel khusus tidak ada
      if (e.code == 'PGRST205' ||
          (e.message.toLowerCase().contains('could not find the table') &&
              e.message.toLowerCase().contains('pendidikan_catatan'))) {
        final generic = {...payload, 'domain': 'pendidikan'};
        await _db
            .from('catatan')
            .upsert(generic, onConflict: 'desa_id,year,domain,section')
            .select()
            .maybeSingle();
        return;
      }
      rethrow;
    }
  }
}
