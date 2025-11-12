import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DesaRepository {
  final SupabaseClient _db = Supabase.instance.client;

  // List desa ringan untuk picker/list-card
  // Menggunakan v_desa_list jika tersedia; jika tidak, fallback ke desa saja.
  Future<List<Map<String, dynamic>>> fetchDesaList({
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final tablesToTry = <String>['v_desa_list', 'desa'];
    for (final table in tablesToTry) {
      try {
        var query = _db.from(table).select();
        if (search != null && search.trim().isNotEmpty) {
          final s = search.trim();
          // Sederhanakan: cari di nama saja agar kompatibel
          query = query.ilike('nama', '%$s%');
        }
        final rows = await query
            .order('nama')
            .range(offset, offset + limit - 1);
        return List<Map<String, dynamic>>.from(rows);
      } catch (_) {
        // coba table berikutnya
      }
    }
    return [];
  }

  // Detail desa + profile (1:1)
  Future<Map<String, dynamic>?> fetchDesaDetailByKode(
    String kodeWilayah,
  ) async {
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
  Future<Map<String, dynamic>?> fetchLatestKependudukanByKode(
    String kodeWilayah,
  ) async {
    // 1) Coba view latest
    try {
      final List withJoin = await _db
          .from('kependudukan')
          .select(
            'total_penduduk,total_kk,laki_laki,perempuan,periode_date,tahun,bulan, desa!inner(kode_wilayah)',
          )
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
  Future<List<Map<String, dynamic>>> fetchAparaturByKode(
    String kodeWilayah,
  ) async {
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

  // Create/insert desa
  // Returns the inserted row (as Map) on success, or throws on error
  Future<Map<String, dynamic>> createDesa({
    required String kodeWilayah,
    required String nama,
    required String kecamatan,
    required String kabupaten,
    required String provinsi,
  }) async {
    try {
      final inserted = await _db
          .from('desa')
          .insert({
            'kode_wilayah': kodeWilayah.trim(),
            'nama': nama.trim(),
            'kecamatan': kecamatan.trim(),
            'kabupaten': kabupaten.trim(),
            'provinsi': provinsi.trim(),
          })
          .select()
          .single();
      return Map<String, dynamic>.from(inserted);
    } on PostgrestException catch (e) {
      // Re-throw with readable message (e.g., duplicate kode_wilayah)
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal menambahkan desa');
    }
  }

  // Update desa by unique kode_wilayah
  Future<Map<String, dynamic>> updateDesaByKode({
    required String kodeWilayah,
    String? nama,
    String? kecamatan,
    String? kabupaten,
    String? provinsi,
  }) async {
    final data = <String, dynamic>{};
    if (nama != null) data['nama'] = nama.trim();
    if (kecamatan != null) data['kecamatan'] = kecamatan.trim();
    if (kabupaten != null) data['kabupaten'] = kabupaten.trim();
    if (provinsi != null) data['provinsi'] = provinsi.trim();
    if (data.isEmpty) {
      throw Exception('Tidak ada perubahan');
    }
    try {
      final updated = await _db
          .from('desa')
          .update(data)
          .eq('kode_wilayah', kodeWilayah)
          .select()
          .single();
      return Map<String, dynamic>.from(updated);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal memperbarui desa');
    }
  }

  // Delete desa by kode_wilayah (assumes DB has ON DELETE CASCADE for related rows)
  Future<void> deleteDesaByKode(String kodeWilayah) async {
    try {
      await _db.from('desa').delete().eq('kode_wilayah', kodeWilayah);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Gagal menghapus desa');
    }
  }

  // Fetch galeri foto from desa_profile.galeri_photos
  Future<List<DesaPhoto>> fetchGaleriFoto(String kodeWilayah) async {
    try {
      debugPrint('🖼️ Fetching galeri foto for kode wilayah: $kodeWilayah');
      
      final response = await _db
          .from('desa')
          .select('id, desa_profile(galeri_photos)')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();

      if (response == null) {
        debugPrint('📸 No desa found');
        return [];
      }

      final desaId = response['id'] as String?;
      debugPrint('🆔 Desa ID: $desaId');

      final profile = response['desa_profile'];
      if (profile == null) {
        debugPrint('📸 No profile data');
        return [];
      }

      final galeriPhotos = profile['galeri_photos'];
      if (galeriPhotos == null || galeriPhotos is! List) {
        debugPrint('📸 No galeri_photos or not a list');
        return [];
      }

      debugPrint('📸 Found ${galeriPhotos.length} photos in galeri_photos');

      return galeriPhotos.asMap().entries.map<DesaPhoto>((entry) {
        final index = entry.key;
        final item = entry.value;
        
        final String photoUrl;
        final String caption;
        final String path;
        
        if (item is String) {
          // Cek apakah sudah full URL atau masih path
          if (item.startsWith('http://') || item.startsWith('https://')) {
            // Sudah full URL, langsung pakai
            photoUrl = item;
            path = item;
          } else {
            // Masih path, generate public URL dari bucket foto-desa
            path = item;
            photoUrl = _db.storage.from('foto-desa').getPublicUrl(item);
          }
          caption = 'Foto ${index + 1}';
        } else if (item is Map) {
          // Support object dengan url/path dan caption
          final urlOrPath = item['url'] as String? ?? item['path'] as String? ?? '';
          
          if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
            photoUrl = urlOrPath;
            path = urlOrPath;
          } else {
            path = urlOrPath;
            photoUrl = urlOrPath.isNotEmpty 
                ? _db.storage.from('foto-desa').getPublicUrl(urlOrPath)
                : '';
          }
          caption = item['caption'] as String? ?? 'Foto ${index + 1}';
        } else {
          photoUrl = '';
          caption = 'Foto ${index + 1}';
          path = '';
        }
        
        debugPrint('🔗 Path: $path -> URL: $photoUrl');
        
        return DesaPhoto(
          url: photoUrl,
          caption: caption,
          path: path,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error fetching galeri: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching galeri: $e');
      return [];
    }
  }

  // Create desa profile
  Future<void> createDesaProfile(Map<String, dynamic> data) async {
    try {
      await _db.from('desa_profile').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal membuat profil desa');
    }
  }

  // Update desa profile
  Future<void> updateDesaProfile(String desaId, Map<String, dynamic> data) async {
    try {
      await _db.from('desa_profile').update(data).eq('desa_id', desaId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal memperbarui profil desa');
    }
  }

  // Insert aparatur
  Future<void> insertAparatur(Map<String, dynamic> data) async {
    try {
      await _db.from('aparatur_desa').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal menambah aparatur');
    }
  }

  // Update aparatur
  Future<void> updateAparatur(String id, Map<String, dynamic> data) async {
    try {
      await _db.from('aparatur_desa').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal memperbarui aparatur');
    }
  }

  // Delete aparatur
  Future<void> deleteAparatur(String id) async {
    try {
      await _db.from('aparatur_desa').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error deleting aparatur: $e');
    }
  }
  
  // Helper method to get photo URL from path
  String getPhotoUrl(String path) {
    // Cek apakah sudah full URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Generate public URL dari bucket foto-desa
    return _db.storage.from('foto-desa').getPublicUrl(path);
  }
  
  // Upload foto ke Supabase Storage
  Future<String> uploadPhoto(String kodeWilayah, File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$kodeWilayah/$fileName';
      
      debugPrint('📤 Uploading photo to: $filePath');
      
      await _db.storage.from('foto-desa').upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          upsert: false,
        ),
      );
      
      debugPrint('✅ Photo uploaded successfully: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      throw Exception('Error uploading photo: $e');
    }
  }
  
  // Update galeri photos di desa_profile
  Future<void> updateGaleriPhotos(String desaId, List<String> photoPaths) async {
    try {
      debugPrint('📝 Updating galeri_photos for desa: $desaId');
      debugPrint('📝 Photo paths: $photoPaths');
      
      await _db.from('desa_profile').update({
        'galeri_photos': photoPaths,
      }).eq('desa_id', desaId);
      
      debugPrint('✅ Galeri photos updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating galeri photos: $e');
      throw Exception('Error updating galeri photos: $e');
    }
  }

  // ===== YEAR-BASED FETCH METHODS =====

  // Kependudukan by year
  Future<List<Map<String, dynamic>>> fetchKependudukanByYear(String kodeWilayah, int year) async {
    try {
      final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
      if (desa == null) return [];
      final desaId = desa['id'] as String;
      final response = await _db
          .from('kependudukan')
          .select('*')
          .eq('desa_id', desaId)
          .eq('tahun', year)
          .order('periode_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching kependudukan by year: $e');
      return [];
    }
  }

  // Kesehatan by year
  Future<List<Map<String, dynamic>>> fetchKesehatanByYear(String kodeWilayah, int year) async {
    try {
      final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
      if (desa == null) return [];
      final desaId = desa['id'] as String;
      final response = await _db
          .from('kesehatan')
          .select('*')
          .eq('desa_id', desaId)
          .eq('tahun', year)
          .order('periode_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching kesehatan by year: $e');
      return [];
    }
  }

  // Infrastruktur by year
  Future<List<Map<String, dynamic>>> fetchInfrastrukturByYear(String kodeWilayah, int year) async {
    try {
      final response = await _db
          .from('infrastruktur')
          .select('*')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', year)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching infrastruktur by year: $e');
      return [];
    }
  }

  // Pendidikan by year
  Future<List<Map<String, dynamic>>> fetchPendidikanByYear(String kodeWilayah, int year) async {
    try {
      final response = await _db
          .from('pendidikan')
          .select('*')
          .eq('kode_wilayah', kodeWilayah)
          .eq('year', year)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching pendidikan by year: $e');
      return [];
    }
  }

  // Kebencanaan by year
  Future<List<Map<String, dynamic>>> fetchKebencanaanByYear(String kodeWilayah, int year) async {
    try {
      final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
      if (desa == null) return [];
      final desaId = desa['id'] as String;
      final response = await _db
          .from('kebencanaan_rekap')
          .select('*')
          .eq('desa_id', desaId)
          .eq('year', year)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching kebencanaan by year: $e');
      return [];
    }
  }

  // Aparatur by year (untuk Profil Desa)
  Future<List<Map<String, dynamic>>> fetchAparaturByYear(String kodeWilayah, int year) async {
    try {
      final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
      if (desa == null) return [];
      final desaId = desa['id'] as String;
      final response = await _db
          .from('aparatur_desa')
          .select('*')
          .eq('desa_id', desaId)
          .eq('year', year)
          .order('urutan', ascending: true)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching aparatur by year: $e');
      return [];
    }
  }

  // Desa profile by year (untuk Profil Desa)
  Future<Map<String, dynamic>?> fetchDesaProfileByYear(String kodeWilayah, int year) async {
    try {
      final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
      if (desa == null) return null;
      final desaId = desa['id'] as String;
      final response = await _db
          .from('desa_profile')
          .select('*')
          .eq('desa_id', desaId)
          .eq('year', year)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('❌ Error fetching desa profile by year: $e');
      return null;
    }
  }

  // Update desa profile by year
  Future<void> updateDesaProfileByYear(String desaId, int year, Map<String, dynamic> data) async {
    data['year'] = year;
    await _db.from('desa_profile').upsert(data, onConflict: 'desa_id,year');
  }

  // Insert/Update kependudukan by year
  Future<void> upsertKependudukan(String kodeWilayah, int year, Map<String, dynamic> data) async {
    final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
    if (desa == null) throw Exception('Desa tidak ditemukan');
    final desaId = desa['id'] as String;

    data['desa_id'] = desaId;
    data['tahun'] = year;
    data['periode_date'] = data['periode_date'] ?? DateTime(year, 12, 31); // Default to end of year

    await _db.from('kependudukan').upsert(data, onConflict: 'desa_id,tahun');
  }

  // Update pendidikan kependudukan (simplified - assuming single record per desa/year)
  Future<void> updatePendidikanKependudukan(String kodeWilayah, int year, Map<String, int> pendidikanData) async {
    final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
    if (desa == null) throw Exception('Desa tidak ditemukan');
    final desaId = desa['id'] as String;

    // Get kependudukan record for this desa/year
    final kependudukan = await _db.from('kependudukan').select('id').eq('desa_id', desaId).eq('tahun', year).maybeSingle();
    if (kependudukan == null) throw Exception('Data kependudukan tidak ditemukan untuk tahun $year');

    final kependudukanId = kependudukan['id'] as String;

    // For each pendidikan category, upsert to kependudukan_pendidikan
    for (final entry in pendidikanData.entries) {
      await _db.from('kependudukan_pendidikan').upsert({
        'kependudukan_id': kependudukanId,
        'kategori': entry.key,
        'jumlah': entry.value,
      });
    }
  }

  // Update pekerjaan kependudukan
  Future<void> updatePekerjaanKependudukan(String kodeWilayah, int year, Map<String, int> pekerjaanData) async {
    final desa = await _db.from('desa').select('id').eq('kode_wilayah', kodeWilayah).maybeSingle();
    if (desa == null) throw Exception('Desa tidak ditemukan');
    final desaId = desa['id'] as String;

    // Get kependudukan record for this desa/year
    final kependudukan = await _db.from('kependudukan').select('id').eq('desa_id', desaId).eq('tahun', year).maybeSingle();
    if (kependudukan == null) throw Exception('Data kependudukan tidak ditemukan untuk tahun $year');

    final kependudukanId = kependudukan['id'] as String;

    // For each pekerjaan, upsert to kependudukan_pekerjaan
    for (final entry in pekerjaanData.entries) {
      final pekerjaan = await _db.from('ref_pekerjaan').select('id').eq('nama', entry.key).maybeSingle();
      if (pekerjaan != null) {
        await _db.from('kependudukan_pekerjaan').upsert({
          'kependudukan_id': kependudukanId,
          'pekerjaan_id': pekerjaan['id'],
          'jumlah': entry.value,
        });
      }
    }
  }

  // Upsert header kependudukan
  Future<void> upsertHeader({
    required String kodeWilayah,
    required int totalPenduduk,
    required int totalKK,
    required int lakiLaki,
    required int perempuan,
    required int produktifBekerja,
    required int produktifTidak,
  }) async {
    final data = {
      'total_penduduk': totalPenduduk,
      'total_kk': totalKK,
      'laki_laki': lakiLaki,
      'perempuan': perempuan,
      'produktif_bekerja': produktifBekerja,
      'produktif_tidak': produktifTidak,
    };
    await upsertKependudukan(kodeWilayah, DateTime.now().year, data);
  }

  // Update pendidikan (alias for updatePendidikanKependudukan)
  Future<void> updatePendidikan({
    required String kodeWilayah,
    required Map<String, int> pendidikanData,
  }) async {
    await updatePendidikanKependudukan(kodeWilayah, DateTime.now().year, pendidikanData);
  }

  // Update pekerjaan (alias for updatePekerjaanKependudukan)
  Future<void> updatePekerjaan({
    required String kodeWilayah,
    required Map<String, int> pekerjaanData,
  }) async {
    await updatePekerjaanKependudukan(kodeWilayah, DateTime.now().year, pekerjaanData);
  }
}

// Model class for desa photos
class DesaPhoto {
  final String url;
  final String caption;
  final String path;

  DesaPhoto({
    required this.url,
    required this.caption,
    required this.path,
  });
}
