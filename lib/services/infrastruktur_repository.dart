import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk fitur Infrastruktur
///
/// Menyediakan pembacaan data per bagian yang digunakan oleh
/// `InfrastrukturScreen` (pendidikan, kesehatan, transportasi & jalan,
/// komunikasi, sanitasi, kebencanaan) dari Supabase.
///
/// Catatan skema yang diharapkan (nama tabel dapat disesuaikan jika berbeda):
/// - infra_pendidikan(jenis enum, jumlah int)
/// - infra_kesehatan_fasilitas(jenis enum, jumlah int)
/// - tenaga_medis(jenis enum, jumlah int)
/// - jalan(jenis enum, panjang_km numeric)
/// - angkutan_umum(jenis enum, jumlah int)
/// - akses_pemerintahan(tujuan enum, label text, jarak_km numeric, waktu_menit int)
/// - komunikasi (paket kolom per tahun)
/// - sanitasi(jenis enum, jumlah int)
/// - kebencanaan(jenis enum, jumlah int)
class InfrastrukturRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Helper: ambil desa.id dari kode_wilayah (jika kolom id ada)
  // ignore: unused_element
  Future<String?> _getDesaId(String kodeWilayah) async {
    try {
      final row = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (row == null) return null;
      return row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Helper: tahun default (misal tahun berjalan) bila tidak diisi
  int _defaultYear() => DateTime.now().year;

  // ---------------------- Summary (untuk grid atas) ----------------------

  Future<int> totalFasilitasPendidikan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('infra_pendidikan')
          .select('jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y);
      return rows.fold<int>(
        0,
        (p, r) => p + ((r['jumlah'] as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return 0;
    }
  }

  Future<int> totalFasilitasKesehatan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('infra_kesehatan_fasilitas')
          .select('jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y);
      return rows.fold<int>(
        0,
        (p, r) => p + ((r['jumlah'] as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return 0;
    }
  }

  Future<int> totalModaTransportasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('angkutan_umum')
          .select('jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y);
      return rows.fold<int>(
        0,
        (p, r) => p + ((r['jumlah'] as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return 0;
    }
  }

  Future<int> totalSaranaSanitasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('sanitasi')
          .select('jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y);
      return rows.fold<int>(
        0,
        (p, r) => p + ((r['jumlah'] as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return 0;
    }
  }

  // ---------------------- Pendidikan ----------------------

  Future<Map<String, int>> getPendidikan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('infra_pendidikan')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  // ---------------------- Kesehatan ----------------------

  Future<Map<String, int>> getKesehatanFasilitas(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('infra_kesehatan_fasilitas')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, int>> getTenagaMedis(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('tenaga_medis')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  // ---------------------- Transportasi & Jalan ----------------------

  Future<Map<String, double>> getJalanKm(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('jalan')
          .select('jenis, panjang_km')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, double>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] =
            ((r['panjang_km'] as num?)?.toDouble() ?? 0.0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, int>> getAngkutan(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('angkutan_umum')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAksesPemerintahan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('akses_pemerintahan')
          .select('tujuan, label, jarak_km, waktu_menit')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('tujuan');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  // ---------------------- Komunikasi ----------------------

  Future<Map<String, dynamic>?> getKomunikasi(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final row = await _db
          .from('komunikasi')
          .select()
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  // ---------------------- Sanitasi & Kebencanaan ----------------------

  Future<Map<String, int>> getSanitasi(String kodeWilayah, {int? year}) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('sanitasi')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, int>> getKebencanaan(
    String kodeWilayah, {
    int? year,
  }) async {
    final y = year ?? _defaultYear();
    try {
      final rows = await _db
          .from('kebencanaan')
          .select('jenis, jumlah')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', y)
          .order('jenis');
      final map = <String, int>{};
      for (final r in rows) {
        map[(r['jenis'] as String)] = ((r['jumlah'] as num?)?.toInt() ?? 0);
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
