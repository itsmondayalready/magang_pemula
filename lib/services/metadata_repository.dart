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
      'nama': (row['nama'] ?? '-') as String,
      'definisi': (row['definisi'] ?? '-') as String,
      'sumber': (row['sumber'] ?? '-') as String,
      'satuan': (row['satuan'] ?? '-') as String,
      'tahun': tahun,
      'frekuensi': (row['frekuensi'] ?? '-') as String,
      'penanggungjawab': (row['penanggungjawab'] ?? '-') as String,
    };
  }
}
