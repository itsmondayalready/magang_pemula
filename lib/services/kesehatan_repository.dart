import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk data Kesehatan (fasilitas dan tenaga medis)
class KesehatanRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Ambil data kesehatan terbaru berdasarkan kode_wilayah
  /// Mengembalikan map dengan semua field fasilitas dan tenaga medis
  Future<Map<String, dynamic>?> fetchLatest(String kodeWilayah) async {
    try {
      print('fetchLatest kesehatan untuk kode: $kodeWilayah');
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

      // Ambil data terbaru dari view atau langsung dari tabel
      final List rows = await _db
          .from('kesehatan')
          .select()
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
      print('Rows kesehatan: $rows');
      
      if (rows.isEmpty) {
        print('Tidak ada data kesehatan untuk desa ini');
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
}
