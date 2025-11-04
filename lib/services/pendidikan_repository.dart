import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk data Pendidikan, berbasis satu tabel serbaguna `infrastruktur`.
///
/// Konvensi skema yang dipakai (pada tabel `public.infrastruktur`):
/// - domain = 'pendidikan'
/// - jenis = kategori jenjang atau item: 'PAUD','TK','SD','SMP','SMA','SMK','Akademi/PT',
///          'Pesantren','Madrasah','TBM','Bahasa','Komputer','Menjahit','Montir', dll.
/// - metric_name:
///   - 'jumlah'                -> jumlah unit (int) per jenis
///   - 'nearest_km'            -> jarak terdekat (numeric)
///   - 'paket_abc'             -> tersedia Paket A/B/C (boolean)
///   - 'keterampilan_unit'     -> jumlah unit lembaga keterampilan (int) per jenis
class PendidikanRepository {
  final SupabaseClient _db = Supabase.instance.client;
  int _defaultYear() => DateTime.now().year;

  /// Ambil jumlah unit untuk jenjang utama (PAUD/TK/SD/SMP/SMA/SMK/Akademi/PT, TBM, Madrasah, Pesantren)
  Future<Map<String, int>> getCounts(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'pendidikan')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  /// Ambil jarak terdekat per jenjang (km)
  Future<Map<String, double>> getNearestKm(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_num')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'pendidikan')
        .eq('metric_name', 'nearest_km')
        .order('jenis');
    final map = <String, double>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] =
          ((r['value_num'] as num?)?.toDouble() ?? 0.0);
    }
    return map;
  }

  /// Ambil flag Paket A/B/C (true/false)
  Future<bool> getPaketABC(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('value_bool')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'pendidikan')
        .eq('metric_name', 'paket_abc')
        .limit(1);
    if (rows.isEmpty) return false;
    return (rows.first['value_bool'] as bool?) ?? false;
  }

  /// Ambil jumlah lembaga keterampilan per kategori
  Future<Map<String, int>> getKeterampilan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'pendidikan')
        .eq('metric_name', 'keterampilan_unit')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }
}
