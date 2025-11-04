import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository alternatif: satu tabel `infrastruktur` serbaguna
///
/// Skema yang diasumsikan:
/// - infrastruktur(
///     id uuid pk,
///     desa_id uuid fk, kode_wilayah text fk, year int,
///     domain text/enum,        -- 'pendidikan','kesehatan_fasilitas','tenaga_medis','jalan','angkutan','akses','komunikasi','sanitasi','kebencanaan'
///     jenis text not null default '-',
///     metric_name text not null,  -- 'jumlah','panjang_km','jarak_km','waktu_menit','bts_count','operator_count','cakupan_4g_pct','internet_desa','komputer_unit','tv_radio_pusat'
///     value_int int, value_num numeric, value_bool boolean,
///     unit text, label text,
///     created_at, updated_at, created_by
///   )
class InfrastrukturRepositorySingle {
  final SupabaseClient _db = Supabase.instance.client;
  int _defaultYear() => DateTime.now().year;

  // ---------------------- Summary totals ----------------------
  Future<int> totalFasilitasPendidikan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'pendidikan')
        .eq('metric_name', 'jumlah');
    return rows.fold<int>(
      0,
      (p, r) => p + ((r['value_int'] as num?)?.toInt() ?? 0),
    );
  }

  Future<int> totalFasilitasKesehatan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'kesehatan_fasilitas')
        .eq('metric_name', 'jumlah');
    return rows.fold<int>(
      0,
      (p, r) => p + ((r['value_int'] as num?)?.toInt() ?? 0),
    );
  }

  Future<int> totalModaTransportasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'angkutan')
        .eq('metric_name', 'jumlah');
    return rows.fold<int>(
      0,
      (p, r) => p + ((r['value_int'] as num?)?.toInt() ?? 0),
    );
  }

  Future<int> totalSaranaSanitasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'sanitasi')
        .eq('metric_name', 'jumlah');
    return rows.fold<int>(
      0,
      (p, r) => p + ((r['value_int'] as num?)?.toInt() ?? 0),
    );
  }

  // ---------------------- Pendidikan ----------------------
  Future<Map<String, int>> getPendidikan(
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
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  // ---------------------- Kesehatan ----------------------
  Future<Map<String, int>> getKesehatanFasilitas(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'kesehatan_fasilitas')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  Future<Map<String, int>> getTenagaMedis(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'tenaga_medis')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  // ---------------------- Transportasi & Jalan ----------------------
  Future<Map<String, double>> getJalanKm(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_num')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'jalan')
        .eq('metric_name', 'panjang_km')
        .order('jenis');
    final map = <String, double>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] =
          ((r['value_num'] as num?)?.toDouble() ?? 0.0);
    }
    return map;
  }

  Future<Map<String, int>> getAngkutan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'angkutan')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getAksesPemerintahan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    // Ambil jarak & waktu per jenis (tujuan)
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, label, metric_name, value_num, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'akses')
        .or('metric_name.eq.jarak_km,metric_name.eq.waktu_menit')
        .order('jenis');

    final byJenis = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      final jenis = (r['jenis'] as String);
      final label = (r['label'] as String?) ?? jenis;
      final metric = (r['metric_name'] as String);
      final rec = byJenis.putIfAbsent(jenis, () => {'label': label});
      if (metric == 'jarak_km') {
        rec['jarak_km'] = ((r['value_num'] as num?)?.toDouble() ?? 0.0);
      } else if (metric == 'waktu_menit') {
        rec['waktu_menit'] = ((r['value_int'] as num?)?.toInt() ?? 0);
      }
    }
    return byJenis.entries.map((e) => {'tujuan': e.key, ...e.value}).toList();
  }

  // ---------------------- Komunikasi ----------------------
  Future<Map<String, dynamic>?> getKomunikasi(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('metric_name, value_int, value_num, value_bool')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'komunikasi')
        .or(
          'metric_name.eq.bts_count,metric_name.eq.operator_count,metric_name.eq.cakupan_4g_pct,metric_name.eq.internet_desa,metric_name.eq.komputer_unit,metric_name.eq.tv_radio_pusat',
        );
    if (rows.isEmpty) return {};
    final out = <String, dynamic>{};
    for (final r in rows) {
      final m = r['metric_name'] as String;
      if (m == 'cakupan_4g_pct') {
        out[m] = ((r['value_num'] as num?)?.toDouble() ?? 0.0);
      } else if (m == 'internet_desa') {
        out[m] = (r['value_bool'] as bool?) ?? false;
      } else {
        out[m] = ((r['value_int'] as num?)?.toInt() ?? 0);
      }
    }
    return out;
  }

  // ---------------------- Sanitasi & Kebencanaan ----------------------
  Future<Map<String, int>> getSanitasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'sanitasi')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  Future<Map<String, int>> getKebencanaan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    final rows = await _db
        .from('infrastruktur')
        .select('jenis, value_int')
        .eq('kode_wilayah', kodeWilayah)
        .eq('year', y)
        .eq('domain', 'kebencanaan')
        .eq('metric_name', 'jumlah')
        .order('jenis');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['jenis'] as String)] = ((r['value_int'] as num?)?.toInt() ?? 0);
    }
    return map;
  }
}
