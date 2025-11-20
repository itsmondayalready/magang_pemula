import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository untuk data kebencanaan.
///
/// Pola:
/// - Ambil record terbaru berdasarkan `kode_wilayah` (skema baru)
/// - Jika kolom itu belum ada, fallback via `desa_id` (skema lama)
class KebencanaanRepository {
  final SupabaseClient _db = Supabase.instance.client;
  bool? _supportsNormalizedCached;
  final Map<String, String?> _snapshotDesaCache =
      {}; // cache snapshot_id -> desa_id

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
      'jenis': row['jenis'] ?? '',
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

  /// Ambil satu snapshot berdasarkan id-nya lalu rangkai detail (skema normalized).
  /// Mengembalikan row yang sudah dirakit seperti fetchLatest(), atau null jika tidak ada.
  Future<Map<String, dynamic>?> fetchBySnapshotId(String snapshotId) async {
    try {
      final snap = await _db
          .from('kebencanaan_rekap')
          .select()
          .eq('id', snapshotId)
          .maybeSingle();
      if (snap == null) return null;
      final snapshot = Map<String, dynamic>.from(snap);

      // Load details for this snapshot
      List<dynamic> rtRows = const [];
      List<dynamic> bantuanRows = const [];
      List<dynamic> penangananRows = const [];
      try {
        rtRows = await _db
            .from('kebencanaan_rt')
            .select()
            .eq('snapshot_id', snapshotId)
            .order('rt_code', ascending: true);
      } catch (e) {
        dev.log('fetchBySnapshotId rt query failed: $e');
      }
      try {
        bantuanRows = await _db
            .from('kebencanaan_bantuan')
            .select()
            .eq('snapshot_id', snapshotId)
            .order('nama', ascending: true);
      } catch (e) {
        dev.log('fetchBySnapshotId bantuan query failed: $e');
      }
      try {
        penangananRows = await _db
            .from('kebencanaan_penanganan')
            .select()
            .eq('snapshot_id', snapshotId)
            .order('urutan', ascending: true);
      } catch (e) {
        dev.log('fetchBySnapshotId penanganan query failed: $e');
      }

      return _assembleRowFromNormalized(
        snapshot: snapshot,
        rtRows: rtRows,
        bantuanRows: bantuanRows,
        penangananRows: penangananRows,
      );
    } catch (e) {
      dev.log('fetchBySnapshotId error: $e');
      return null;
    }
  }

  /// Check if normalized detail tables exist (cached).
  Future<bool> supportsNormalized() async {
    if (_supportsNormalizedCached != null) {
      return _supportsNormalizedCached!;
    }
    try {
      // Probe one of the detail tables; if it errors (table missing), assume legacy.
      await _db.from('kebencanaan_rt').select('id').limit(1);
      _supportsNormalizedCached = true;
    } catch (e) {
      dev.log(
        'Normalized detail tables not available, using legacy JSON columns. $e',
      );
      _supportsNormalizedCached = false;
    }
    return _supportsNormalizedCached!;
  }

  /// Update legacy JSON detail columns on kebencanaan table (rt_detail, bantuan, penanganan).
  Future<void> updateLegacyDetails({
    required String kebencanaanId,
    Map<String, dynamic>? rtDetail,
    Map<String, int>? bantuan,
    List<dynamic>? penanganan,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rt_detail': rtDetail,
        'bantuan': bantuan,
        'penanganan': penanganan,
      }..removeWhere((k, v) => v == null);
      if (payload.isEmpty) return;
      await _db.from('kebencanaan').update(payload).eq('id', kebencanaanId);
    } catch (e) {
      dev.log('updateLegacyDetails error: $e');
    }
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
      'snapshot_id': snapshot['id'], // simpan id snapshot untuk edit
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

  // ============================= MUTATIONS =============================
  /// Ambil desa_id dari kode_wilayah (cache sederhana bisa diterapkan di layer atas).
  Future<String?> getDesaIdByKode(String kodeWilayah) async {
    try {
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      return desa?['id'] as String?;
    } catch (e) {
      dev.log('getDesaIdByKode error: $e');
      return null;
    }
  }

  /// Upsert (insert/update) rekap kebencanaan.
  /// Jika [snapshotId] null akan insert baru, jika ada akan update.
  /// Mengembalikan id snapshot (yang baru atau yang diupdate).
  Future<String?> upsertRekap({
    String? snapshotId,
    required String kodeWilayah,
    required String jenis,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? periodeDate,
    String? periodeLabel,
    int? totalRumah,
    int? totalKk,
    int? totalJiwa,
    int? lansia,
    int? bumil,
    int? balita,
  }) async {
    try {
      // Ensure desa_id available for normalized table (NOT NULL constraint)
      String? desaId;
      try {
        final d = await _db
            .from('desa')
            .select('id')
            .eq('kode_wilayah', kodeWilayah)
            .maybeSingle();
        desaId = d?['id'] as String?;
      } catch (e) {
        dev.log('fetch desa_id failed (still proceed for legacy fallback): $e');
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'kode_wilayah': kodeWilayah,
        'jenis': jenis,
        'period_start': periodStart?.toIso8601String(),
        'period_end': periodEnd?.toIso8601String(),
        'periode_date': periodeDate?.toIso8601String(),
        'periode_label': (periodeLabel ?? '').trim().isEmpty
            ? null
            : periodeLabel!.trim(),
        'total_rumah': totalRumah,
        'total_kk': totalKk,
        'total_jiwa': totalJiwa,
        'lansia': lansia,
        'bumil': bumil,
        'balita': balita,
        'desa_id': desaId, // normalized table expects this
      }..removeWhere((k, v) => v == null);

      if (snapshotId == null) {
        try {
          // Try update existing row for this kode_wilayah + jenis (replace-mode)
          final existing = await _db
              .from('kebencanaan_rekap')
              .select('id')
              .eq('kode_wilayah', kodeWilayah)
              .eq('jenis', jenis)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (existing != null) {
            final exId = existing['id'];
            await _db.from('kebencanaan_rekap').update(payload).eq('id', exId);
            return exId == null ? null : exId.toString();
          }

          // No existing -> insert new
          final inserted = await _db
              .from('kebencanaan_rekap')
              .insert(payload)
              .select('id')
              .maybeSingle();
          final rawId = inserted?['id'];
          return rawId == null ? null : rawId.toString();
        } catch (e) {
          // If normalized table does not exist (legacy DB), fallback to legacy kebencanaan table
          dev.log('kebencanaan_rekap insert failed, trying legacy table: $e');
          return await _legacyUpsertRekap(payload, kodeWilayah, jenis);
        }
      } else {
        try {
          // Update specific snapshot id; if no row updated (e.g., id not found), fallback to replace-mode by kode_wilayah+jenis
          final updated = await _db
              .from('kebencanaan_rekap')
              .update(payload)
              .eq('id', snapshotId)
              .select('id')
              .maybeSingle();
          if (updated != null) return snapshotId;

          // Fallback: find existing by kode_wilayah+jenis
          final existing = await _db
              .from('kebencanaan_rekap')
              .select('id')
              .eq('kode_wilayah', kodeWilayah)
              .eq('jenis', jenis)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (existing != null) {
            final exId = existing['id'];
            await _db.from('kebencanaan_rekap').update(payload).eq('id', exId);
            return exId == null ? null : exId.toString();
          }

          // As a last resort, insert new
          final inserted = await _db
              .from('kebencanaan_rekap')
              .insert(payload)
              .select('id')
              .maybeSingle();
          final rawId = inserted?['id'];
          return rawId == null ? null : rawId.toString();
        } catch (e) {
          dev.log('kebencanaan_rekap update failed, trying legacy table: $e');
          return await _legacyUpsertRekap(
            payload,
            kodeWilayah,
            jenis,
            snapshotId: snapshotId,
          );
        }
      }
    } catch (e) {
      dev.log('upsertRekap error: $e');
      // final attempt: try legacy upsert (best-effort)
      try {
        return await _legacyUpsertRekap(
          {},
          kodeWilayah,
          jenis,
          snapshotId: snapshotId,
        );
      } catch (e2) {
        dev.log('legacy fallback also failed: $e2');
        return null;
      }
    }
  }

  /// Fallback for older schema where kebencanaan is a single table.
  /// Accepts the normalized payload (may contain period/total fields) and will
  /// map relevant keys to kebencanaan table columns. Returns inserted/updated id
  /// as String if available, otherwise null.
  Future<String?> _legacyUpsertRekap(
    Map<String, dynamic> payload,
    String kodeWilayah,
    String jenis, {
    String? snapshotId,
  }) async {
    try {
      // Quick probe: if legacy table doesn't exist, abort early to avoid noisy errors
      try {
        await _db.from('kebencanaan').select('id').limit(1);
      } catch (probeErr) {
        if (probeErr is PostgrestException && probeErr.code == 'PGRST205') {
          dev.log(
            'Legacy table kebencanaan not found (schema migrated). Skipping legacy fallback.',
          );
          return null;
        }
      }
      final desa = await _db
          .from('desa')
          .select('id')
          .eq('kode_wilayah', kodeWilayah)
          .maybeSingle();
      if (desa == null) throw Exception('Desa tidak ditemukan');
      final desaId = desa['id'];

      // Map keys to legacy columns
      final Map<String, dynamic> legacy = <String, dynamic>{
        'desa_id': desaId,
        'jenis': jenis,
        'periode_date': payload['periode_date'] ?? payload['periode_date'],
        'periode_label': payload['periode_label'] ?? payload['periode_label'],
        'total_rumah': payload['total_rumah'] ?? payload['total_rumah'],
        'total_kk': payload['total_kk'] ?? payload['total_kk'],
        'total_jiwa': payload['total_jiwa'] ?? payload['total_jiwa'],
        'lansia': payload['lansia'] ?? payload['lansia'],
        'bumil': payload['bumil'] ?? payload['bumil'],
        'balita': payload['balita'] ?? payload['balita'],
      }..removeWhere((k, v) => v == null);

      if (snapshotId != null) {
        // Try update existing kebencanaan row by id
        try {
          await _db.from('kebencanaan').update(legacy).eq('id', snapshotId);
          return snapshotId;
        } catch (e) {
          dev.log('legacy update by id failed: $e');
        }
      }

      // Otherwise try to find existing by desa_id + jenis (latest)
      try {
        final existing = await _db
            .from('kebencanaan')
            .select('id')
            .eq('desa_id', desaId)
            .eq('jenis', jenis)
            .order('period_end', ascending: false)
            .order('periode_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (existing != null) {
          await _db.from('kebencanaan').update(legacy).eq('id', existing['id']);
          final exId = existing['id'];
          return exId == null ? null : exId.toString();
        }
      } catch (e) {
        dev.log('legacy find existing failed: $e');
      }

      // Insert new row into kebencanaan
      final inserted = await _db
          .from('kebencanaan')
          .insert(legacy)
          .select('id')
          .maybeSingle();
      final insId = inserted?['id'];
      return insId == null ? null : insId.toString();
    } catch (e) {
      dev.log('legacyUpsertRekap error: $e');
      return null;
    }
  }

  // -------------------------- RT DETAIL --------------------------
  Future<void> upsertRtDetail({
    required String snapshotId,
    required String rtCode,
    int? rumah,
    int? kk,
    int? jiwa,
    int? lansia,
    int? bumil,
    int? balita,
    int? bayi,
  }) async {
    try {
      final desaId = await _getSnapshotDesaId(snapshotId);
      final existing = await _db
          .from('kebencanaan_rt')
          .select('id')
          .eq('snapshot_id', snapshotId)
          .eq('rt_code', rtCode)
          .maybeSingle();
      final Map<String, dynamic> payload = <String, dynamic>{
        'snapshot_id': snapshotId,
        'rt_code': rtCode,
        'rumah': rumah,
        'kk': kk,
        'jiwa': jiwa,
        'lansia': lansia,
        'bumil': bumil,
        'balita': balita,
        'bayi': bayi,
        'desa_id': desaId,
      }..removeWhere((k, v) => v == null);
      if (existing == null) {
        await _db.from('kebencanaan_rt').insert(payload);
      } else {
        await _db
            .from('kebencanaan_rt')
            .update(payload)
            .eq('id', existing['id']);
      }
    } catch (e) {
      dev.log('upsertRtDetail error: $e');
    }
  }

  Future<void> deleteRtDetail({
    required String snapshotId,
    required String rtCode,
  }) async {
    try {
      await _db
          .from('kebencanaan_rt')
          .delete()
          .eq('snapshot_id', snapshotId)
          .eq('rt_code', rtCode);
    } catch (e) {
      dev.log('deleteRtDetail error: $e');
    }
  }

  // -------------------------- BANTUAN --------------------------
  Future<void> upsertBantuan({
    required String snapshotId,
    required String nama,
    String? jenis,
    int? jumlah,
  }) async {
    try {
      final desaId = await _getSnapshotDesaId(snapshotId);
      final existing = await _db
          .from('kebencanaan_bantuan')
          .select('id')
          .eq('snapshot_id', snapshotId)
          .eq('nama', nama)
          .maybeSingle();
      final Map<String, dynamic> payload = <String, dynamic>{
        'snapshot_id': snapshotId,
        'nama': nama,
        'jenis': (jenis ?? '').trim().isEmpty ? null : jenis!.trim(),
        'jumlah': jumlah,
        'desa_id': desaId,
      }..removeWhere((k, v) => v == null);
      if (existing == null) {
        await _db.from('kebencanaan_bantuan').insert(payload);
      } else {
        await _db
            .from('kebencanaan_bantuan')
            .update(payload)
            .eq('id', existing['id']);
      }
    } catch (e) {
      dev.log('upsertBantuan error: $e');
    }
  }

  Future<void> deleteBantuan({
    required String snapshotId,
    required String nama,
  }) async {
    try {
      await _db
          .from('kebencanaan_bantuan')
          .delete()
          .eq('snapshot_id', snapshotId)
          .eq('nama', nama);
    } catch (e) {
      dev.log('deleteBantuan error: $e');
    }
  }

  // -------------------------- PENANGANAN --------------------------
  Future<void> upsertPenanganan({
    required String snapshotId,
    required int urutan,
    required String deskripsi,
  }) async {
    try {
      final desaId = await _getSnapshotDesaId(snapshotId);
      final existing = await _db
          .from('kebencanaan_penanganan')
          .select('id')
          .eq('snapshot_id', snapshotId)
          .eq('urutan', urutan)
          .maybeSingle();
      final Map<String, dynamic> payload = <String, dynamic>{
        'snapshot_id': snapshotId,
        'urutan': urutan,
        'deskripsi': deskripsi.trim(),
        'desa_id': desaId,
      }..removeWhere((k, v) => v == null);
      if (existing == null) {
        await _db.from('kebencanaan_penanganan').insert(payload);
      } else {
        await _db
            .from('kebencanaan_penanganan')
            .update(payload)
            .eq('id', existing['id']);
      }
    } catch (e) {
      dev.log('upsertPenanganan error: $e');
    }
  }

  Future<void> deletePenanganan({
    required String snapshotId,
    required int urutan,
  }) async {
    try {
      await _db
          .from('kebencanaan_penanganan')
          .delete()
          .eq('snapshot_id', snapshotId)
          .eq('urutan', urutan);
    } catch (e) {
      dev.log('deletePenanganan error: $e');
    }
  }

  // ======================= INTERNAL HELPERS =======================
  // Clear all details for a snapshot (useful to replace fully on save)
  Future<void> clearRtDetails(String snapshotId) async {
    try {
      await _db.from('kebencanaan_rt').delete().eq('snapshot_id', snapshotId);
    } catch (e) {
      dev.log('clearRtDetails error: $e');
    }
  }

  Future<void> clearBantuan(String snapshotId) async {
    try {
      await _db
          .from('kebencanaan_bantuan')
          .delete()
          .eq('snapshot_id', snapshotId);
    } catch (e) {
      dev.log('clearBantuan error: $e');
    }
  }

  Future<void> clearPenanganan(String snapshotId) async {
    try {
      await _db
          .from('kebencanaan_penanganan')
          .delete()
          .eq('snapshot_id', snapshotId);
    } catch (e) {
      dev.log('clearPenanganan error: $e');
    }
  }

  // ======================= INTERNAL HELPERS =======================
  Future<String?> _getSnapshotDesaId(String snapshotId) async {
    if (_snapshotDesaCache.containsKey(snapshotId)) {
      return _snapshotDesaCache[snapshotId];
    }
    try {
      final row = await _db
          .from('kebencanaan_rekap')
          .select('desa_id')
          .eq('id', snapshotId)
          .maybeSingle();
      final desaId = row?['desa_id'] as String?;
      _snapshotDesaCache[snapshotId] = desaId;
      return desaId;
    } catch (e) {
      dev.log('getSnapshotDesaId error: $e');
      _snapshotDesaCache[snapshotId] = null;
      return null;
    }
  }

  // ------------------- Jenis (list of disaster types) -------------------
  /// Fetch available `jenis` options.
  ///
  /// Tries the `kebencanaan_jenis` table first; if the table doesn't exist
  /// or an error occurs, falls back to `SharedPreferences` key
  /// `kebencanaan_jenis_options` (list of strings). If nothing found, returns
  /// a sensible default list.
  Future<List<String>> fetchJenisOptions() async {
    try {
      final rows = await _db
          .from('kebencanaan_jenis')
          .select('name')
          .order('name', ascending: true);
      if (rows.isNotEmpty) {
        // Safely extract, trim, deduplicate, and filter non-empty names.
        final names =
            rows
                .whereType<Map>()
                .map((m) => (m['name'] ?? '').toString().trim())
                .where((s) => s.isNotEmpty)
                .toSet() // ensure uniqueness
                .toList()
              ..sort(); // keep sorted order for UI consistency
        if (names.isNotEmpty) return names;
      }
    } catch (e) {
      dev.log(
        'fetchJenisOptions: table query failed, falling back to prefs: $e',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('kebencanaan_jenis_options');
      if (list != null && list.isNotEmpty) return list;
    } catch (e) {
      dev.log('fetchJenisOptions: prefs fallback failed: $e');
    }

    // Default set
    return ['banjir', 'longsor', 'angin', 'kebakaran'];
  }

  /// Add a new `jenis` option. Tries inserting into `kebencanaan_jenis` table,
  /// if available. On failure falls back to adding into `SharedPreferences`.
  Future<void> addJenisOption(String name) async {
    final nm = name.trim();
    if (nm.isEmpty) return;
    try {
      // Check existing first to avoid duplicates
      final exists = await _db
          .from('kebencanaan_jenis')
          .select('id')
          .eq('name', nm)
          .maybeSingle();
      if (exists == null) {
        await _db.from('kebencanaan_jenis').insert({'name': nm});
      }
      return;
    } catch (e) {
      dev.log('addJenisOption: insert failed, trying prefs fallback: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          prefs.getStringList('kebencanaan_jenis_options') ?? <String>[];
      if (!list.contains(nm)) {
        list.add(nm);
        await prefs.setStringList('kebencanaan_jenis_options', list);
      }
    } catch (e) {
      dev.log('addJenisOption: prefs fallback also failed: $e');
    }
  }
}
