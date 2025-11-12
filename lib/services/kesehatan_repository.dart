import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk data Kesehatan (fasilitas dan tenaga medis)
class KesehatanRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Ambil data kesehatan terbaru berdasarkan kode_wilayah dan tahun
  /// Mengembalikan map dengan semua field fasilitas dan tenaga medis
  Future<Map<String, dynamic>?> fetchLatest(String kodeWilayah, {int? year}) async {
    try {
      print('fetchLatest kesehatan untuk kode: $kodeWilayah, tahun: $year');
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) {
        print('Desa tidak ditemukan untuk kode: $kodeWilayah');
        return null;
      }
      final desaId = desa['id'] as String;
      print('Desa ID: $desaId');

      // Query dengan filter tahun jika disediakan
      var query = _db
          .from('kesehatan')
          .select()
          .eq('desa_id', desaId);

      if (year != null) {
        query = query.eq('tahun', year);
      }

      final List rows = await query
          .order('periode_date', ascending: false)
          .limit(1);
      print('Rows kesehatan: $rows');

      if (rows.isEmpty) {
        print('Tidak ada data kesehatan untuk desa ini${year != null ? ' pada tahun $year' : ''}');
        return null;
      }

      final result = Map<String, dynamic>.from(rows.first as Map);
      print('Result kesehatan: $result');
      return result;
    } catch (e) {
      print('Error fetchLatest kesehatan: $e');
      return null;
    }
  }

  /// Helper: ambil map fasilitas dari row database
  /// Mengembalikan map nama_fasilitas -> jumlah (semua kategori ditampilkan)
  Map<String, int> extractFasilitas(Map<String, dynamic>? row) {
    if (row == null) return {};

    final result = <String, int>{};
    final fields = {
      'rumah_sakit': 'Rumah Sakit',
      'puskesmas': 'Puskesmas',
      'poliklinik': 'Poliklinik',
      'tempat_praktik_dokter': 'Tempat Praktik Dokter',
      'tempat_praktik_bidan': 'Tempat Praktik Bidan',
      'poskesdes': 'Poskesdes',
      'polindes': 'Polindes',
      'apotek': 'Apotek',
      'posyandu': 'Posyandu',
      'posbindu': 'Posbindu',
    };

    for (final entry in fields.entries) {
      final val = (row[entry.key] ?? 0) as int;
      result[entry.value] = val;
    }

    return result;
  }

  /// Helper: ambil map tenaga medis dari row database
  /// Mengembalikan map nama_tenaga -> jumlah (semua kategori ditampilkan)
  Map<String, int> extractTenagaMedis(Map<String, dynamic>? row) {
    if (row == null) return {};

    final result = <String, int>{};
    final fields = {
      'kader_kb_kia': 'Kader KB/KIA',
      'dokter_pria': 'Dokter Pria',
      'dokter_wanita': 'Dokter Wanita',
      'dokter_gigi': 'Dokter Gigi',
      'bidan': 'Bidan',
      'perawat': 'Perawat',
      'tenaga_kesehatan_lain': 'Tenaga Kesehatan Lain',
    };

    for (final entry in fields.entries) {
      final val = (row[entry.key] ?? 0) as int;
      result[entry.value] = val;
    }

    return result;
  }

  /// Update atau insert data kesehatan
  Future<void> upsertKesehatan({
    required String kodeWilayah,
    required Map<String, int> fasilitasData,
    required Map<String, int> tenagaMedisData,
    DateTime? periodeDate,
  }) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) throw Exception('Desa tidak ditemukan');
      final desaId = desa['id'] as String;

      // Gunakan periode sekarang jika tidak diberikan
      final periode = periodeDate ?? DateTime.now();

      // Cek apakah sudah ada data untuk periode ini
      final existing = await _db
          .from('kesehatan')
          .select('id')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1)
          .maybeSingle();

      // Map field names
      final fasilitasFields = {
        'Rumah Sakit': 'rumah_sakit',
        'Puskesmas': 'puskesmas',
        'Poliklinik': 'poliklinik',
        'Tempat Praktik Dokter': 'tempat_praktik_dokter',
        'Tempat Praktik Bidan': 'tempat_praktik_bidan',
        'Poskesdes': 'poskesdes',
        'Polindes': 'polindes',
        'Apotek': 'apotek',
        'Posyandu': 'posyandu',
        'Posbindu': 'posbindu',
      };

      final tenagaMedisFields = {
        'Kader KB/KIA': 'kader_kb_kia',
        'Dokter Pria': 'dokter_pria',
        'Dokter Wanita': 'dokter_wanita',
        'Dokter Gigi': 'dokter_gigi',
        'Bidan': 'bidan',
        'Perawat': 'perawat',
        'Tenaga Kesehatan Lain': 'tenaga_kesehatan_lain',
      };

      final data = <String, dynamic>{
        'desa_id': desaId,
        'periode_date': periode.toIso8601String(),
      };

      // Add fasilitas data
      for (final entry in fasilitasData.entries) {
        final fieldName = fasilitasFields[entry.key];
        if (fieldName != null) {
          data[fieldName] = entry.value;
        }
      }

      // Add tenaga medis data
      for (final entry in tenagaMedisData.entries) {
        final fieldName = tenagaMedisFields[entry.key];
        if (fieldName != null) {
          data[fieldName] = entry.value;
        }
      }

      if (existing != null) {
        // Update existing
        await _db.from('kesehatan').update(data).eq('id', existing['id']);
      } else {
        // Insert new
        await _db.from('kesehatan').insert(data);
      }
    } catch (e) {
      print('Error upsertKesehatan: $e');
      rethrow;
    }
  }
}
