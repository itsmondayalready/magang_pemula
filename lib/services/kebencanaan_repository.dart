import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk data kebencanaan.
///
/// Pola:
/// - Ambil record terbaru berdasarkan `kode_wilayah` (skema baru)
/// - Jika kolom itu belum ada, fallback via `desa_id` (skema lama)
class KebencanaanRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Ambil satu record kebencanaan terbaru untuk desa+jenis tertentu.
  /// Mengembalikan row apa adanya (map) atau null jika tidak ada.
  Future<Map<String, dynamic>?> fetchLatest(
    String kodeWilayah, {
    String jenis = 'banjir',
  }) async {
    // 1) Coba skema NORMAL (tabel terpisah): kebencanaan_snapshot + detail
    try {
      final normalized = await _fetchLatestNormalized(
        kodeWilayah,
        jenis: jenis,
      );
      if (normalized != null) return normalized;
    } catch (e) {
      dev.log('normalized fetch error, fallback to legacy: $e');
    }

    // Coba query langsung berdasarkan kolom kode_wilayah (skema terbaru)
    try {
      final List rows = await _db
          .from('kebencanaan')
          .select()
          .eq('kode_wilayah', kodeWilayah)
          .eq('jenis', jenis)
          .order('period_end', ascending: false)
          .order('periode_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        return Map<String, dynamic>.from(rows.first as Map);
      }
    } catch (e) {
      // Bisa terjadi jika kolom kode_wilayah belum ada (skema lama)
      dev.log('kebencanaan: direct query error, will fallback. $e');
    }

    // Fallback untuk skema lama: cari desa_id lalu filter di kebencanaan
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) return null;
      final desaId = desa['id'];

      final List rows = await _db
          .from('kebencanaan')
          .select()
          .eq('desa_id', desaId)
          .eq('jenis', jenis)
          .order('period_end', ascending: false)
          .order('periode_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return Map<String, dynamic>.from(rows.first as Map);
    } catch (e) {
      dev.log('Error fetchLatest kebencanaan (fallback): $e');
      return null;
    }
  }

  /// Bentuk data sesuai kebutuhan UI kebencanaan_screen.dart
  /// Struktur hasil:
  /// {
  ///   'periode': String,
  ///   'total_rumah': int,
  ///   'total_kk': int,
  ///   'total_jiwa': int,
  ///   'lansia': int,
  ///   'bumil': int,
  ///   'balita': int,
  ///   'rt': Map<String, dynamic>, // dari kolom rt_detail
  ///   'bantuan': Map<String, int>,
  ///   'penanganan': List<dynamic>,
  /// }
  Map<String, dynamic> toScreenData(Map<String, dynamic> row) {
    final periodeLabel = _formatPeriode(row);
    return {
      'periode': periodeLabel,
      'total_rumah': (row['total_rumah'] ?? 0) as int,
      'total_kk': (row['total_kk'] ?? 0) as int,
      'total_jiwa': (row['total_jiwa'] ?? 0) as int,
      'lansia': (row['lansia'] ?? 0) as int,
      'bumil': (row['bumil'] ?? 0) as int,
      'balita': (row['balita'] ?? 0) as int,
      'rt': Map<String, dynamic>.from(row['rt_detail'] ?? const {}),
      'bantuan': Map<String, int>.from(row['bantuan'] ?? const {}),
      // Optional: daftar bantuan mentah dari skema normalized (punya 'jenis')
      'bantuan_raw': List<dynamic>.from(row['bantuan_raw'] ?? const []),
      'penanganan': List<dynamic>.from(row['penanganan'] ?? const []),
    };
  }

  String _formatPeriode(Map<String, dynamic> row) {
    final label = row['periode_label'] as String?;
    if (label != null && label.trim().isNotEmpty) return label;

    final start =
        row['period_start'] as String?; // Supabase returns date as String
    final end = row['period_end'] as String?;
    try {
      if (start != null && end != null) {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        if (s.year == e.year && s.month == e.month) {
          return _formatMonthYear(s);
        }
        return '${_monthName(s.month)}–${_formatMonthYear(e)}';
      }
      final periodeDate = row['periode_date'] as String?;
      if (periodeDate != null) {
        final d = DateTime.parse(periodeDate);
        return _formatMonthYear(d);
      }
    } catch (_) {}
    return '';
  }

  String _formatMonthYear(DateTime d) => '${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (m < 1 || m > 12) return '';
    return names[m - 1];
  }

  /// Skema NORMALIZED (versi penamaan baru: rekap/rt/bantuan/penanganan)
  /// Ambil snapshot terbaru lalu tarik detail RT, bantuan, dan penanganan.
  Future<Map<String, dynamic>?> _fetchLatestNormalized(
    String kodeWilayah, {
    required String jenis,
  }) async {
    // Ambil snapshot terbaru berdasarkan kode_wilayah & jenis
    Map<String, dynamic>? snapshot;
    try {
      final snap = await _db
          .from('kebencanaan_rekap')
          .select()
          .eq('kode_wilayah', kodeWilayah)
          .eq('jenis', jenis)
          .order('period_end', ascending: false, nullsFirst: false)
          .order('periode_date', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (snap == null) {
        // Tidak ada snapshot untuk kode ini.
        return null;
      }
      snapshot = Map<String, dynamic>.from(snap);
    } catch (e) {
      // Tabel snapshot bisa belum ada (belum migrasi)
      dev.log('snapshot query failed: $e');
      return null;
    }

    final snapshotId = snapshot['id'];
    if (snapshotId == null) return null;

    // Tarik detail RT
    List<dynamic> rtRows = const [];
    try {
      rtRows = await _db
          .from('kebencanaan_rt')
          .select()
          .eq('snapshot_id', snapshotId)
          .order('rt_code', ascending: true);
    } catch (e) {
      dev.log('rt_detail query failed: $e');
    }

    // Tarik bantuan
    List<dynamic> bantuanRows = const [];
    try {
      bantuanRows = await _db
          .from('kebencanaan_bantuan')
          .select()
          .eq('snapshot_id', snapshotId)
          .order('nama', ascending: true);
    } catch (e) {
      dev.log('bantuan query failed: $e');
    }

    // Tarik penanganan
    List<dynamic> penangananRows = const [];
    try {
      penangananRows = await _db
          .from('kebencanaan_penanganan')
          .select()
          .eq('snapshot_id', snapshotId)
          .order('urutan', ascending: true);
    } catch (e) {
      dev.log('penanganan query failed: $e');
    }

    // Rakit ke bentuk baris "legacy" yang dipahami toScreenData
    final row = _assembleRowFromNormalized(
      snapshot: snapshot,
      rtRows: rtRows,
      bantuanRows: bantuanRows,
      penangananRows: penangananRows,
    );
    return row;
  }

  Map<String, dynamic> _assembleRowFromNormalized({
    required Map<String, dynamic> snapshot,
    required List<dynamic> rtRows,
    required List<dynamic> bantuanRows,
    required List<dynamic> penangananRows,
  }) {
    // Bentuk rt_detail sebagai map: { '001': {rumah, kk, jiwa, lansia, bumil, balita, bayi}, ... }
    final Map<String, dynamic> rtDetail = {};
    for (final r in rtRows) {
      final m = Map<String, dynamic>.from(r as Map);
      final code = (m['rt_code'] ?? '').toString();
      if (code.isEmpty) continue;
      rtDetail[code] = {
        'rumah': (m['rumah'] ?? 0) as int,
        'kk': (m['kk'] ?? 0) as int,
        'jiwa': (m['jiwa'] ?? 0) as int,
        'lansia': (m['lansia'] ?? 0) as int,
        'bumil': (m['bumil'] ?? 0) as int,
        'balita': (m['balita'] ?? 0) as int,
        'bayi': (m['bayi'] ?? 0) as int,
      };
    }

    // Bantuan sebagai map nama->jumlah dan juga list mentah dengan jenis
    final Map<String, int> bantuan = {};
    final List<Map<String, dynamic>> bantuanRaw = [];
    for (final r in bantuanRows) {
      final m = Map<String, dynamic>.from(r as Map);
      final nama = (m['nama'] ?? '').toString();
      final jumlah = (m['jumlah'] ?? 0) as int;
      if (nama.isNotEmpty) {
        bantuan[nama] = jumlah;
        bantuanRaw.add({'nama': nama, 'jenis': m['jenis'], 'jumlah': jumlah});
      }
    }

    // Penanganan sebagai list deskripsi
    final List<dynamic> penanganan = [];
    for (final r in penangananRows) {
      final m = Map<String, dynamic>.from(r as Map);
      final desc = (m['deskripsi'] ?? '').toString();
      if (desc.isNotEmpty) penanganan.add(desc);
    }

    // Gabungkan dengan kolom-kolom periode & total dari snapshot
    final Map<String, dynamic> row = {
      'jenis': snapshot['jenis'],
      'kode_wilayah': snapshot['kode_wilayah'],
      'desa_id': snapshot['desa_id'],
      'period_start': snapshot['period_start'],
      'period_end': snapshot['period_end'],
      'periode_date': snapshot['periode_date'],
      'periode_label': snapshot['periode_label'],
      'total_rumah': snapshot['total_rumah'] ?? 0,
      'total_kk': snapshot['total_kk'] ?? 0,
      'total_jiwa': snapshot['total_jiwa'] ?? 0,
      'lansia': snapshot['lansia'] ?? 0,
      'bumil': snapshot['bumil'] ?? 0,
      'balita': snapshot['balita'] ?? 0,
      'rt_detail': rtDetail,
      'bantuan': bantuan,
      'bantuan_raw': bantuanRaw,
      'penanganan': penanganan,
      'created_at': snapshot['created_at'],
    };
    return row;
  }
}
