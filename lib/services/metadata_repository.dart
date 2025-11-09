import 'package:supabase_flutter/supabase_flutter.dart';

class MetadataRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAll(String kodeWilayah) async {
    // 1) Coba query berdasarkan kolom kode_wilayah (skema terbaru)
    List rows = [];
    try {
      rows = await _db
          .from('metadata_item')
          .select()
          .eq('kode_wilayah', kodeWilayah)
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false);
    } catch (_) {
      rows = [];
    }

    // 2) Fallback skema lama: cari desa_id lalu filter metadata by desa_id
    if (rows.isEmpty) {
      try {
        final desa = await _db
            .from('desa')
            .select('id')
            .eq('kode_wilayah', kodeWilayah)
            .maybeSingle();
        if (desa != null) {
          final desaId = desa['id'];
          rows = await _db
              .from('metadata_item')
              .select()
              .eq('desa_id', desaId)
              .order('updated_at', ascending: false)
              .order('created_at', ascending: false);
        }
      } catch (_) {
        rows = [];
      }
    }

    return rows
        .map<Map<String, dynamic>>(
          (e) => toScreenItem(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Map<String, dynamic> toScreenItem(Map<String, dynamic> row) {
    final tahunText = (row['tahun_text'] as String?)?.trim();
    String tahun = tahunText ?? '';
    if (tahun.isEmpty) {
      final start = row['tahun_start'] as int?;
      final end = row['tahun_end'] as int?;
      if (start != null && end != null) {
        tahun = start == end ? '$start' : '$start-$end';
      } else if (start != null) {
        tahun = '$start';
      }
    }

    return {
      'id': row['id'],
      'nama': (row['nama'] ?? '-') as String,
      'definisi': (row['definisi'] ?? '-') as String,
      'sumber': (row['sumber'] ?? '-') as String,
      'satuan': (row['satuan'] ?? '-') as String,
      'tahun': tahun,
      'frekuensi': (row['frekuensi'] ?? '-') as String,
      'penanggungjawab': (row['penanggungjawab'] ?? '-') as String,
      // Simpan raw untuk kebutuhan edit (tahun_start/end/text)
      '_raw': row,
    };
  }

  // ====================== MUTATIONS (CRUD) ======================
  Future<String?> getDesaIdByKode(String kodeWilayah) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      return desa?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Upsert metadata item. Menggunakan (kode_wilayah, nama) sebagai pseudo unique key.
  Future<void> upsertItem({
    required String kodeWilayah,
    String? desaId,
    required String nama,
    required String definisi,
    required String sumber,
    required String satuan,
    String? tahunText,
    int? tahunStart,
    int? tahunEnd,
    required String frekuensi,
    required String penanggungJawab,
  }) async {
    final payload = {
      'kode_wilayah': kodeWilayah,
      if (desaId != null) 'desa_id': desaId,
      'nama': nama.trim(),
      'definisi': definisi.trim(),
      'sumber': sumber.trim(),
      'satuan': satuan.trim(),
      'tahun_text': (tahunText ?? '').trim().isEmpty ? null : tahunText!.trim(),
      'tahun_start': tahunStart,
      'tahun_end': tahunEnd,
      'frekuensi': frekuensi.trim(),
      'penanggungjawab': penanggungJawab.trim(),
    }..removeWhere((k, v) => v == null);
    // Cek existing
    final existing = await _db
        .from('metadata_item')
        .select('id')
        .eq('kode_wilayah', kodeWilayah)
        .eq('nama', nama.trim())
        .maybeSingle();
    if (existing == null) {
      await _db.from('metadata_item').insert(payload);
    } else {
      await _db
          .from('metadata_item')
          .update(payload)
          .eq('id', existing['id']);
    }
  }

  Future<void> deleteItem({
    required String kodeWilayah,
    required String nama,
  }) async {
    await _db
        .from('metadata_item')
        .delete()
        .eq('kode_wilayah', kodeWilayah)
        .eq('nama', nama.trim());
  }
}
