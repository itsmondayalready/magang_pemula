import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository khusus untuk data Kependudukan (header, pendidikan, pekerjaan)
class KependudukanRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Ambil header kependudukan terbaru berdasarkan kode_wilayah
  /// Mengembalikan map dengan kunci yang umum dipakai UI:
  /// - total_penduduk, total_kk, laki_laki, perempuan
  /// - produktif_bekerja, produktif_tidak_bekerja (jika tersedia)
  /// - periode_date, tahun, bulan
  Future<Map<String, dynamic>?> fetchLatestHeader(String kodeWilayah) async {
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
      if (rows.isEmpty) return null;
      return Map<String, dynamic>.from(rows.first as Map);
    } catch (_) {
      return null;
    }
  }

  /// Ambil distribusi pendidikan untuk periode terbaru sebuah desa.
  /// Hasil berupa map category->jumlah untuk 5 kategori tetap:
  /// ['Tidak Tamat SD','Tamat SD','Tamat SMP','Tamat SMA','Akademi/PT']
  Future<Map<String, int>> fetchPendidikanLatest(String kodeWilayah) async {
    try {
      print('fetchPendidikanLatest untuk kode: $kodeWilayah');
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) {
        print('Desa tidak ditemukan untuk kode: $kodeWilayah');
        return {};
      }
      final desaId = desa['id'] as String;
      print('Desa ID: $desaId');

      // Ambil periode terbaru dari header agar konsisten
      final List headers = await _db
          .from('kependudukan')
          .select('id, periode_date')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
      print('Headers kependudukan: $headers');
      if (headers.isEmpty) {
        print('Header kosong, tidak ada data kependudukan');
        return {};
      }
      final kependudukanId = headers.first['id'];
      final periodeDate = headers.first['periode_date'];
      print('Kependudukan ID: $kependudukanId, Periode: $periodeDate');

      final List rows = await _db
          .from('kependudukan_pendidikan')
          .select('kategori,jumlah')
          .eq('kependudukan_id', kependudukanId)
          .order('kategori');
      print('Rows pendidikan untuk kependudukan_id: $rows');

      final result = <String, int>{};
      for (final r in rows) {
        final cat = (r['kategori'] ?? '') as String;
        final val = (r['jumlah'] ?? 0) as int;
        result[cat] = val;
      }
      print('Result pendidikan: $result');
      return result;
    } catch (e) {
      print('Error fetchPendidikanLatest: $e');
      return {};
    }
  }

  /// Ambil distribusi pekerjaan (master/detail) untuk periode terbaru.
  /// Kembalikan map nama_pekerjaan -> jumlah.
  Future<Map<String, int>> fetchPekerjaanLatest(String kodeWilayah) async {
    try {
      print('fetchPekerjaanLatest untuk kode: $kodeWilayah');
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) {
        print('Desa tidak ditemukan untuk kode: $kodeWilayah');
        return {};
      }
      final desaId = desa['id'] as String;
      print('Desa ID: $desaId');

      final List headers = await _db
          .from('kependudukan')
          .select('id, periode_date')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
      print('Headers kependudukan untuk pekerjaan: $headers');
      if (headers.isEmpty) {
        print('Header kosong, tidak ada data kependudukan');
        return {};
      }
      final kependudukanId = headers.first['id'];
      final periodeDate = headers.first['periode_date'];
      print('Kependudukan ID: $kependudukanId, Periode: $periodeDate');

      final List rows = await _db
          .from('kependudukan_pekerjaan')
          .select('jumlah, pekerjaan_id, ref_pekerjaan (nama)')
          .eq('kependudukan_id', kependudukanId)
          .order('jumlah', ascending: false);
      print('Rows pekerjaan untuk kependudukan_id: $rows');

      final result = <String, int>{};
      for (final r in rows) {
        final ref = r['ref_pekerjaan'] as Map<String, dynamic>?;
        final name = (ref != null ? ref['nama'] : null) as String?;
        final val = (r['jumlah'] ?? 0) as int;
        final pid = r['pekerjaan_id'];
        final label = (name != null && name.isNotEmpty)
            ? name
            : (pid != null ? 'Pekerjaan $pid' : 'Lainnya');
        result[label] = val;
      }
      print('Result pekerjaan: $result');
      return result;
    } catch (e) {
      print('Error fetchPekerjaanLatest: $e');
      return {};
    }
  }

  /// Update atau insert header kependudukan
  Future<void> upsertHeader({
    required String kodeWilayah,
    required int totalPenduduk,
    required int totalKK,
    required int lakiLaki,
    required int perempuan,
    required int produktifBekerja,
    required int produktifTidak,
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
          .from('kependudukan')
          .select('id')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1)
          .maybeSingle();

      final data = {
        'desa_id': desaId,
        // total_penduduk adalah generated column (laki_laki + perempuan)
        'total_kk': totalKK,
        'laki_laki': lakiLaki,
        'perempuan': perempuan,
        'produktif_bekerja': produktifBekerja,
        'produktif_tidak_bekerja': produktifTidak,
        'periode_date': periode.toIso8601String(),
        // tahun dan bulan adalah generated columns, tidak perlu di-set
      };

      if (existing != null) {
        // Update existing
        await _db
            .from('kependudukan')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Insert new
        await _db.from('kependudukan').insert(data);
      }
    } catch (e) {
      print('Error upsertHeader: $e');
      rethrow;
    }
  }

  /// Update data pendidikan untuk periode terbaru
  Future<void> updatePendidikan({
    required String kodeWilayah,
    required Map<String, int> pendidikanData,
  }) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) throw Exception('Desa tidak ditemukan');
      final desaId = desa['id'] as String;

      // Ambil kependudukan_id terbaru
      final headers = await _db
          .from('kependudukan')
          .select('id')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
      if (headers.isEmpty) throw Exception('Header kependudukan tidak ada');
      final kependudukanId = headers.first['id'];

      // Hapus data lama
      await _db
          .from('kependudukan_pendidikan')
          .delete()
          .eq('kependudukan_id', kependudukanId);

      // Insert data baru
      final rows = pendidikanData.entries
          .where((e) => e.value > 0)
          .map((e) => {
                'kependudukan_id': kependudukanId,
                'kategori': e.key,
                'jumlah': e.value,
              })
          .toList();

      if (rows.isNotEmpty) {
        await _db.from('kependudukan_pendidikan').insert(rows);
      }
    } catch (e) {
      print('Error updatePendidikan: $e');
      rethrow;
    }
  }

  /// Update data pekerjaan untuk periode terbaru
  Future<void> updatePekerjaan({
    required String kodeWilayah,
    required Map<String, int> pekerjaanData,
  }) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) throw Exception('Desa tidak ditemukan');
      final desaId = desa['id'] as String;

      // Ambil kependudukan_id terbaru
      final headers = await _db
          .from('kependudukan')
          .select('id')
          .eq('desa_id', desaId)
          .order('periode_date', ascending: false)
          .limit(1);
      if (headers.isEmpty) throw Exception('Header kependudukan tidak ada');
      final kependudukanId = headers.first['id'];

      // Hapus data lama
      await _db
          .from('kependudukan_pekerjaan')
          .delete()
          .eq('kependudukan_id', kependudukanId);

      // Untuk setiap pekerjaan, cari atau buat ref_pekerjaan
      for (final entry in pekerjaanData.entries) {
        if (entry.value <= 0) continue;

        final namaPekerjaan = entry.key.trim();
        if (namaPekerjaan.isEmpty) continue;

        // Cari pekerjaan di ref_pekerjaan
        var refPekerjaan = await _db
            .from('ref_pekerjaan')
            .select('id')
            .eq('nama', namaPekerjaan)
            .maybeSingle();

        String pekerjaanId;
        if (refPekerjaan != null) {
          pekerjaanId = refPekerjaan['id'] as String;
        } else {
          // Insert pekerjaan baru dengan kode auto-generated
          // Generate kode dari nama (lowercase, replace spasi dengan underscore)
          final kode = namaPekerjaan
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
              .replaceAll(RegExp(r'_+'), '_')
              .replaceAll(RegExp(r'^_|_$'), '');
          
          final inserted = await _db
              .from('ref_pekerjaan')
              .insert({
                'nama': namaPekerjaan,
                'kode': kode,
              })
              .select('id')
              .single();
          pekerjaanId = inserted['id'] as String;
        }

        // Insert ke kependudukan_pekerjaan
        await _db.from('kependudukan_pekerjaan').insert({
          'kependudukan_id': kependudukanId,
          'pekerjaan_id': pekerjaanId,
          'jumlah': entry.value,
        });
      }
    } catch (e) {
      print('Error updatePekerjaan: $e');
      rethrow;
    }
  }
}
