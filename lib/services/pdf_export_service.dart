import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

/// Service untuk mengekspor data ke PDF dengan berbagai format laporan
class PdfExportService {
  // Gunakan format sederhana tanpa locale untuk menghindari masalah inisialisasi
  static String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Ekspor data kependudukan ke PDF
  static Future<void> exportKependudukan({
    required String desaName,
    required String kodeWilayah,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // Ekstrak data dari parameter
      final totalPenduduk = (data['total_penduduk'] ?? 0) as int;
      final totalKK = (data['total_kk'] ?? 0) as int;
      final lakiLaki = (data['laki_laki'] ?? 0) as int;
      final perempuan = (data['perempuan'] ?? 0) as int;
      final usia0_14 = (data['usia_0_14'] ?? 0) as int;
      final usia15_64 = (data['usia_15_64'] ?? 0) as int;
      final usia65Plus = (data['usia_65_plus'] ?? 0) as int;
      final year = (data['year'] ?? now.year) as int;

      

      // First page(s): general info, demographics, gender, age
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            title: 'LAPORAN DATA KEPENDUDUKAN',
            subtitle: '$desaName ($kodeWilayah)',
            date: now,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInfoSection('Informasi Umum', [
              ['Nama Desa', desaName],
              ['Kode Wilayah', kodeWilayah],
              ['Jenis Bencana', (data['jenis'] ?? '')?.toString() ?? ''],
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),

            pw.SizedBox(height: 20),

            _buildInfoSection('Ringkasan Demografis', [
              ['Total Penduduk', _formatNumber(totalPenduduk) + ' jiwa'],
              ['Total Kepala Keluarga', _formatNumber(totalKK) + ' KK'],
            ]),

            pw.SizedBox(height: 20),

            _buildDataTable(
              title: 'Data Berdasarkan Jenis Kelamin',
              headers: ['Jenis Kelamin', 'Jumlah', 'Persentase'],
              rows: [
                ['Laki-laki', _formatNumber(lakiLaki), _formatPercentage(lakiLaki, totalPenduduk)],
                ['Perempuan', _formatNumber(perempuan), _formatPercentage(perempuan, totalPenduduk)],
                ['Total', _formatNumber(totalPenduduk), '100.0%'],
              ],
            ),

            pw.SizedBox(height: 20),

            _buildDataTable(
              title: 'Data Berdasarkan Kelompok Usia',
              headers: ['Kelompok Usia', 'Jumlah', 'Persentase'],
              rows: [
                ['0-14 tahun', _formatNumber(usia0_14), _formatPercentage(usia0_14, totalPenduduk)],
                ['15-64 tahun', _formatNumber(usia15_64), _formatPercentage(usia15_64, totalPenduduk)],
                ['65+ tahun', _formatNumber(usia65Plus), _formatPercentage(usia65Plus, totalPenduduk)],
                ['Total', _formatNumber(totalPenduduk), '100.0%'],
              ],
            ),

            pw.SizedBox(height: 30),
          ],
        ),
      );

      // If pekerjaan exists, add a dedicated page so title and table stay together
      if ((data['pekerjaan'] as Map?)?.isNotEmpty ?? false) {
        final pekerjaanMap = (data['pekerjaan'] as Map?) ?? {};
        final pekerjaan = pekerjaanMap.map<String, int>((k, v) => MapEntry(k.toString(), (v as int?) ?? 0));
        final totalForTable = pekerjaan.values.fold<int>(0, (s, v) => s + v);
        final rows = pekerjaan.entries.map((e) => [
              e.key,
              _formatNumber(e.value),
              _formatPercentage(e.value, totalForTable),
            ]).toList();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            header: (context) => _buildHeader(
              title: 'LAPORAN DATA KEPENDUDUKAN',
              subtitle: '$desaName ($kodeWilayah)',
              date: now,
            ),
            footer: (context) => _buildFooter(context),
            build: (context) => [
              _buildDataTable(
                title: 'Distribusi Pekerjaan',
                headers: ['Pekerjaan', 'Jumlah', 'Persentase'],
                rows: rows,
              ),
              pw.SizedBox(height: 20),
            ],
          ),
        );
      }

      await _savePdf(
        pdf,
        'Laporan_Kependudukan_${desaName}_$year.pdf',
        context,
        desaName: desaName,
      );
    } catch (e) {
      _showError(context, 'Gagal membuat laporan kependudukan: $e');
    }
  }

  /// Ekspor data kesehatan ke PDF
  static Future<void> exportKesehatan({
    required String desaName,
    required String kodeWilayah,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // Ensure we show a fixed set of facility and tenaga categories.
      // Prefer nested maps if available (kesehatan_screen passes 'fasilitas' and 'tenaga_medis')
      // Default categories (ensure some expected names always present)
      final defaultFasilitasNames = <String>['Rumah Sakit', 'Puskesmas', 'Poliklinik', 'Tempat Praktik Dokter', 'Tempat Praktik Bidan', 'Poskesdes', 'Polindes', 'Apotek', 'Posyandu', 'Posbindu'];
      final defaultTenagaNames = <String>['Kader KB/KIA', 'Dokter Pria', 'Dokter Wanita', 'Dokter Gigi', 'Bidan', 'Perawat', 'Tenaga Kesehatan Lain'];

      // Debug: show incoming kesehatan/fasilitas payload for exportKesehatan
      try {
        debugPrint('--- exportKesehatan INPUT DEBUG ---');
        debugPrint('data["fasilitas"] raw: ' + jsonEncode(data['fasilitas'] ?? {}));
        debugPrint('data["tenaga_medis"] raw: ' + jsonEncode(data['tenaga_medis'] ?? {}));
      } catch (e) {
        debugPrint('exportKesehatan debug encode failed: $e');
      }

      final nestedFasilitas = _normalizeFacilities(data['fasilitas'], defaultFasilitasNames);
      final nestedTenaga = _normalizeFacilities(data['tenaga_medis'], defaultTenagaNames);

      // Debug: per-entry check for kesehatan mapping
      try {
        debugPrint('--- kesehatan (exportKesehatan) per-entry ---');
        final rawF = data['fasilitas'] ?? {};
        if (rawF is Map) {
          for (final e in rawF.entries) {
            debugPrint('fasilitas raw key=${e.key} value=${e.value} -> _toInt=${_toInt(e.value)}');
          }
        } else if (rawF is Iterable) {
          int i = 0;
          for (final it in rawF) {
            debugPrint('fasilitas raw list[$i]=${it.toString()} -> _toInt=${_toInt(it)}');
            i++;
          }
        }
      } catch (e) {
        debugPrint('exportKesehatan per-entry debug failed: $e');
      }

      // Merge nested maps and defaults: include any key present in nested plus defaults (nested values preferred)
      final facilities = <String, int>{};
      for (final name in {...defaultFasilitasNames, ...nestedFasilitas.keys}) {
        facilities[name] = nestedFasilitas[name] ?? 0;
      }

      final tenages = <String, int>{};
      for (final name in {...defaultTenagaNames, ...nestedTenaga.keys}) {
        tenages[name] = nestedTenaga[name] ?? 0;
      }

      final totalFasilitas = (data['total_fasilitas'] as int?) ?? facilities.values.fold<int>(0, (s, v) => s + v);
      final totalTenagaMedis = (data['total_tenaga_medis'] as int?) ?? tenages.values.fold<int>(0, (s, v) => s + v);
      final year = (data['year'] ?? now.year) as int;

      

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            title: 'LAPORAN DATA KESEHATAN',
            subtitle: '$desaName ($kodeWilayah)',
            date: now,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInfoSection('Informasi Umum', [
              ['Nama Desa', desaName],
              ['Kode Wilayah', kodeWilayah],
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),
            
            pw.SizedBox(height: 20),
            
            _buildInfoSection('Ringkasan Fasilitas & Tenaga Kesehatan', [
              ['Total Fasilitas Kesehatan', _formatNumber(totalFasilitas) + ' unit'],
              ['Total Tenaga Medis', _formatNumber(totalTenagaMedis) + ' orang'],
            ]),
            
            pw.SizedBox(height: 20),
            
            _buildDataTable(
              title: 'Data Fasilitas Kesehatan',
              headers: ['Jenis Fasilitas', 'Jumlah', 'Satuan'],
              rows: [
                ...facilities.entries.map((e) => [e.key, _formatNumber(e.value), 'Unit']),
                ['Total', _formatNumber(totalFasilitas), 'Unit'],
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            _buildDataTable(
              title: 'Data Tenaga Medis',
              headers: ['Jenis Tenaga', 'Jumlah', 'Satuan'],
              rows: [
                ...tenages.entries.map((e) => [e.key, _formatNumber(e.value), 'Orang']),
                ['Total', _formatNumber(totalTenagaMedis), 'Orang'],
              ],
            ),
            
            pw.SizedBox(height: 30),
          ],
        ),
      );

      await _savePdf(
        pdf,
        'Laporan_Kesehatan_${desaName}_$year.pdf',
        context,
        desaName: desaName,
      );
    } catch (e) {
      _showError(context, 'Gagal membuat laporan kesehatan: $e');
    }
  }

  /// Ekspor data infrastruktur dan pendidikan ke PDF
  static Future<void> exportInfrastruktur({
    required String desaName,
    required String kodeWilayah,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      
      final infrastruktur = data['infrastruktur'] as Map<String, dynamic>? ?? {};
      final pendidikan = data['pendidikan'] as Map<String, dynamic>? ?? {};
      final transportasi = data['transportasi'] as Map<String, dynamic>? ?? {};
      final komunikasi = data['komunikasi'] as Map<String, dynamic>? ?? {};
      final sanitasi = data['sanitasi'] as Map<String, dynamic>? ?? {};
      // If caller signaled pendidikan-only export, we will skip health sections
      final isPendidikanOnly = (data['is_pendidikan_report'] as bool?) ?? false;
      // Debug: print raw structures received for infra-related export
      try {
        debugPrint('--- exportInfrastruktur INPUT DEBUG ---');
        debugPrint('data keys: ' + jsonEncode(data.keys.toList()));
        debugPrint('infrastruktur (raw): ' + jsonEncode(infrastruktur));
        debugPrint('pendidikan (raw): ' + jsonEncode(pendidikan));
        debugPrint('transportasi (raw): ' + jsonEncode(transportasi));
        debugPrint('komunikasi (raw): ' + jsonEncode(komunikasi));
        debugPrint('sanitasi (raw): ' + jsonEncode(sanitasi));
        debugPrint('kesehatan (raw): ' + jsonEncode(data['kesehatan'] ?? {}));
        debugPrint('fasilitas root (raw): ' + jsonEncode(data['fasilitas'] ?? {}));
      } catch (e) {
        debugPrint('exportInfrastruktur debug encode failed: $e');
      }
      // Kesehatan: accept nested/flexible formats for fasilitas and fallback to top-level `data['fasilitas']`.
      final kesehatan = data['kesehatan'] as Map<String, dynamic>? ?? {};
      final defaultKesehatanFasilitas = <String>['Rumah Sakit', 'Puskesmas', 'Poliklinik', 'Tempat Praktik Dokter', 'Tempat Praktik Bidan', 'Poskesdes', 'Polindes', 'Apotek', 'Posyandu', 'Posbindu'];
      // Choose the best source for kesehatan fasilitas:
      // 1. kesehatan['fasilitas'] if provided
      // 2. top-level kesehatan map itself if it looks like a {name: count} map
      // 3. fallback to data['fasilitas'] if present
      dynamic chosenKesehatanRaw;
      if (kesehatan.containsKey('fasilitas') && kesehatan['fasilitas'] != null) {
        chosenKesehatanRaw = kesehatan['fasilitas'];
      } else if (kesehatan.isNotEmpty) {
        // Heuristic: if values look numeric or numeric-strings, treat kesehatan as the map of counts
        bool looksLikeCountMap = false;
        try {
          for (final v in kesehatan.values) {
            if (v is num) {
              looksLikeCountMap = true;
              break;
            }
            if (v is String && RegExp(r'\d').hasMatch(v)) {
              looksLikeCountMap = true;
              break;
            }
            if (v is Map || v is Iterable) {
              // ignore complex entries for this heuristic
            }
          }
        } catch (_) {
          looksLikeCountMap = false;
        }
        if (looksLikeCountMap) chosenKesehatanRaw = kesehatan;
      }
      chosenKesehatanRaw ??= data['fasilitas'];

      final nestedKesehatanFasilitas = _normalizeFacilities(chosenKesehatanRaw, defaultKesehatanFasilitas);
      final kesehatanFasilitas = <String, int>{};
      for (final name in {...defaultKesehatanFasilitas, ...nestedKesehatanFasilitas.keys}) {
        kesehatanFasilitas[name] = nestedKesehatanFasilitas[name] ?? 0;
      }

      // Debug: show per-entry normalization and converted integer and chosen source
      try {
        debugPrint('--- kesehatan fasilitas normalization ---');
        debugPrint('chosen kesehatan raw source: ' + (chosenKesehatanRaw == kesehatan['fasilitas'] ? 'kesehatan["fasilitas"]' : (chosenKesehatanRaw == kesehatan ? 'kesehatan' : 'data["fasilitas"]')));
        final rawNested = chosenKesehatanRaw ?? {};
        if (rawNested is Map) {
          for (final e in rawNested.entries) {
            debugPrint('raw key=${e.key} rawValue=${e.value} -> _toInt=${_toInt(e.value)}');
          }
        } else if (rawNested is Iterable) {
          int idx = 0;
          for (final item in rawNested) {
            debugPrint('raw list item[$idx]=${item.toString()} -> _toInt=${_toInt(item)}');
            idx++;
          }
        }
        for (final e in nestedKesehatanFasilitas.entries) {
          debugPrint('normalized entry ${e.key}=${e.value}');
        }
      } catch (e) {
        debugPrint('kesehatan normalization debug failed: $e');
      }
      
      final kebencanaan = data['kebencanaan'] as Map<String, dynamic>? ?? {};
      // Akses Pemerintahan can be provided as a List or a Map. Normalize to List<Map<String, dynamic>>
      final aksesRaw = data['akses_pemerintahan'];
      final List<Map<String, dynamic>> aksesPemerintahan = [];
      if (aksesRaw is List) {
        for (final item in aksesRaw) {
          if (item is Map) {
            aksesPemerintahan.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (aksesRaw is Map) {
        // If the map's values are maps, use those; otherwise convert entries into simple maps
        final firstValue = aksesRaw.values.isNotEmpty ? aksesRaw.values.first : null;
        if (firstValue is Map) {
          // aksesRaw looks like { 'Tujuan': { 'jarak_km': X, 'waktu_menit': Y }, ... }
          // Preserve the top-level key as 'tujuan' while copying inner map values.
          for (final e in aksesRaw.entries) {
            if (e.value is Map) {
              final m = Map<String, dynamic>.from(e.value as Map);
              m['tujuan'] = e.key;
              aksesPemerintahan.add(m);
            }
          }
        } else {
          for (final e in aksesRaw.entries) {
            aksesPemerintahan.add({
              'tujuan': e.key,
              'label': e.value?.toString() ?? '',
              'jarak_km': null,
              'waktu_menit': null,
            });
          }
        }
      }

      // Debug: akses_pemerintahan raw and normalized inspection
      try {
        debugPrint('--- akses_pemerintahan RAW DEBUG ---');
        debugPrint('aksesRaw runtimeType: ${aksesRaw.runtimeType}');
        try {
          debugPrint('aksesRaw content: ' + jsonEncode(aksesRaw ?? {}));
        } catch (e) {
          debugPrint('aksesRaw encode failed: $e');
        }
      } catch (e) {
        debugPrint('akses raw debug failed: $e');
      }

      try {
        debugPrint('--- akses_pemerintahan NORMALIZED DEBUG ---');
        debugPrint('normalized count: ${aksesPemerintahan.length}');
        for (int i = 0; i < aksesPemerintahan.length; i++) {
          final entry = aksesPemerintahan[i];
          debugPrint('entry[$i] keys=${entry.keys.toList()} values=${entry.values.toList()}');
          final tujuan = (entry['tujuan'] ?? entry['label'] ?? entry['name'] ?? entry['destination'] ?? entry['dest'])?.toString() ?? '<EMPTY>';
          debugPrint('computed tujuan for entry[$i]: $tujuan');
          debugPrint('jarak_km=${entry['jarak_km']}, waktu_menit=${entry['waktu_menit']}');
        }
      } catch (e) {
        debugPrint('akses normalization debug failed: $e');
      }
      final year = (data['year'] ?? now.year) as int;

      // choose title: if caller signaled a pendidikan-only report, adapt title
      final reportTitle = isPendidikanOnly ? 'LAPORAN PENDIDIKAN' : 'LAPORAN INFRASTRUKTUR';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            title: reportTitle,
            subtitle: '$desaName ($kodeWilayah)',
            date: now,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInfoSection('Informasi Umum', [
              ['Nama Desa', desaName],
              ['Kode Wilayah', kodeWilayah],
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),
            
            pw.SizedBox(height: 20),
            
            if (infrastruktur.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Infrastruktur',
                headers: ['Jenis Infrastruktur', 'Jumlah', 'Satuan'],
                rows: infrastruktur.entries.map((e) => [
                  _formatKey(e.key),
                  _formatNumber(e.value as int? ?? 0),
                  'Unit'
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            if (pendidikan.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Fasilitas Pendidikan',
                headers: ['Jenis Sekolah', 'Jumlah', 'Satuan'],
                rows: pendidikan.entries.map((e) => [
                  _expandPendidikanLabel(e.key),
                  _formatNumber(e.value as int? ?? 0),
                  'Sekolah'
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Kesehatan (tambahan): tampilkan fasilitas dan tenaga medis jika tersedia
            if (!isPendidikanOnly && kesehatanFasilitas.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Fasilitas Kesehatan',
                headers: ['Jenis Fasilitas', 'Jumlah', 'Satuan'],
                rows: [
                  ...kesehatanFasilitas.entries.map((e) => [_formatKey(e.key), _formatNumber(e.value), 'Unit']),
                  ['Total', _formatNumber(kesehatanFasilitas.values.fold<int>(0, (s, v) => s + v)), 'Unit'],
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Transportasi (jalan / angkutan)
            if (transportasi.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Transportasi & Jalan',
                headers: ['Jenis', 'Jumlah', 'Satuan'],
                rows: transportasi.entries.map((e) {
                  final rawKey = e.key.toString().toLowerCase();
                  final val = e.value;
                  // Determine if this entry represents a road length (km)
                  final looksLikeKm = rawKey.contains('km') || rawKey.contains('aspal') || rawKey.contains('beton') || rawKey.contains('tanah') || rawKey.contains('jalan');
                  String display;
                  if (val is double) {
                    display = val.toString();
                  } else if (val is num && val % 1 != 0) {
                    display = val.toString();
                  } else if (val is int) {
                    display = _formatNumber(val);
                  } else {
                    display = val?.toString() ?? '0';
                  }
                  final satuan = looksLikeKm ? 'km' : 'Unit';
                  return [_formatKey(e.key), display, satuan];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Komunikasi
            if (komunikasi.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Komunikasi',
                headers: ['Jenis', 'Nilai', 'Satuan'],
                rows: komunikasi.entries.map((e) {
                  final val = e.value;
                  return [_formatKey(e.key), val.toString(), 'Unit'];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Sanitasi
            if (sanitasi.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Sanitasi',
                headers: ['Jenis', 'Jumlah', 'Satuan'],
                rows: sanitasi.entries.map((e) => [_formatKey(e.key), _formatNumber(e.value as int? ?? 0), 'Unit']).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Kebencanaan
            if (kebencanaan.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Kebencanaan',
                headers: ['Jenis', 'Nilai', 'Satuan'],
                rows: kebencanaan.entries.map((e) => [_formatKey(e.key), e.value?.toString() ?? '', 'Unit']).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Akses Pemerintahan (list of maps)
            if (aksesPemerintahan.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Akses Pemerintahan',
                headers: ['Tujuan', 'Jarak (km)', 'Waktu (menit)'],
                rows: aksesPemerintahan.map((item) {
                  final m = Map<String, dynamic>.from(item as Map);
                  final tujuan = (m['tujuan'] ?? m['label'] ?? m['name'] ?? m['destination'] ?? m['dest'])?.toString() ?? '';
                  return [
                    tujuan,
                    (m['jarak_km'] != null) ? (m['jarak_km'].toString()) : '',
                    (m['waktu_menit'] != null) ? (m['waktu_menit'].toString()) : '',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            pw.SizedBox(height: 10),
          ],
        ),
      );

      final outFilename = isPendidikanOnly
          ? 'Laporan_Pendidikan_${desaName}_$year.pdf'
          : 'Laporan_Infrastruktur_${desaName}_$year.pdf';

      await _savePdf(
        pdf,
        outFilename,
        context,
        desaName: desaName,
      );
    } catch (e) {
      _showError(context, 'Gagal membuat laporan infrastruktur: $e');
    }
  }

  /// Ekspor data kebencanaan ke PDF
  static Future<void> exportKebencanaan({
    required String desaName,
    required String kodeWilayah,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      
      final rekap = data['rekap'] as Map<String, dynamic>? ?? {};
      final rtDetails = data['rt_details'] as List? ?? [];
      final bantuan = data['bantuan'] as Map<String, dynamic>? ?? {};
      final penanganan = data['penanganan'] as Map<String, dynamic>? ?? {};
      // Debug: trace kebencanaan payload shapes and numeric conversions
      try {
        debugPrint('--- exportKebencanaan INPUT DEBUG ---');
        try {
          debugPrint('rekap raw: ' + jsonEncode(rekap));
        } catch (e) {
          debugPrint('rekap raw encode failed: $e');
        }

        try {
          debugPrint('rt_details runtimeType: ${rtDetails.runtimeType}');
          debugPrint('rt_details raw: ' + jsonEncode(rtDetails));
        } catch (e) {
          debugPrint('rt_details encode failed: $e');
        }

        // Per-RT diagnostics
        try {
          if (rtDetails is Iterable) {
            int idx = 0;
            for (final rt in rtDetails) {
              try {
                    debugPrint('rt[$idx] raw: ' + jsonEncode(rt));
              } catch (_) {
                debugPrint('rt[$idx] toString: ' + rt.toString());
              }
              if (rt is Map) {
                    // Also include KK and Rumah diagnostics (support many possible keys)
                    final dbgKk = _toInt(rt['kk'] ?? rt['jumlah_kk'] ?? rt['total_kk'] ?? rt['kk_terdampak'] ?? rt['jumlah_kk_terdampak'] ?? rt['jumlah_keluarga'] ?? rt['total_keluarga']);
                    final dbgRumah = _toInt(rt['rumah'] ?? rt['jumlah_rumah'] ?? rt['total_rumah'] ?? rt['rumah_terdampak'] ?? rt['rumah_rusak'] ?? rt['jumlah_rumah_terdampak']);
                    debugPrint('rt[$idx] -> rt_number=${rt["rt_number"]}, kk=$dbgKk, rumah=$dbgRumah, rusak_ringan=${_toInt(rt['rusak_ringan'])}, rusak_sedang=${_toInt(rt['rusak_sedang'])}, rusak_berat=${_toInt(rt['rusak_berat'])}, korban_jiwa=${_toInt(rt['korban_jiwa'] ?? rt['jiwa'])}');
              }
              idx++;
            }
          }
        } catch (e) {
          debugPrint('rt_details per-entry debug failed: $e');
        }

        try {
          debugPrint('bantuan runtimeType: ${bantuan.runtimeType}');
          debugPrint('bantuan raw: ' + jsonEncode(bantuan));
        } catch (e) {
          debugPrint('bantuan encode failed: $e');
        }

        try {
          if (bantuan is Map) {
            for (final e in bantuan.entries) {
              debugPrint('bantuan entry key=${e.key} raw=${e.value} -> _toInt=${_toInt(e.value)}');
            }
          }
        } catch (e) {
          debugPrint('bantuan per-entry debug failed: $e');
        }

        try {
          debugPrint('penanganan runtimeType: ${penanganan.runtimeType}');
          debugPrint('penanganan raw: ' + jsonEncode(penanganan));
        } catch (e) {
          debugPrint('penanganan encode failed: $e');
        }
      } catch (e) {
        debugPrint('exportKebencanaan input debug failed: $e');
      }
      final year = (data['year'] ?? now.year) as int;

      // Compute fallback totals from rt_details when rekap is empty or has zeros
      int computedTotalKorban = 0;
      try {
        for (final rt in rtDetails) {
          if (rt is Map) computedTotalKorban += _toInt(rt['korban_jiwa'] ?? rt['jiwa']);
        }
      } catch (_) {
        computedTotalKorban = 0;
      }
      final int rekapKorban = _toInt(rekap['korban_jiwa']);
      final int displayKorban = (rekapKorban > 0) ? rekapKorban : computedTotalKorban;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            title: 'LAPORAN DATA KEBENCANAAN',
            subtitle: '$desaName ($kodeWilayah)',
            date: now,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInfoSection('Informasi Umum', [
              ['Nama Desa', desaName],
              ['Kode Wilayah', kodeWilayah],
              ['Jenis Bencana', (data['jenis'] ?? '').toString()],
              ['Total Jiwa Terdampak', _formatNumber(displayKorban) + ' jiwa'],
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),
            
            pw.SizedBox(height: 20),
            
            // Show jenis bencana (if provided) in Informasi Umum instead of separate rekap table
            
            // Data per RT (columns: RT, Rumah, KK, Jiwa) -- swap Rumah and KK positions
            if (rtDetails.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Kebencanaan per RT',
                headers: ['RT', 'KK', 'Rumah', 'Jiwa'],
                rows: rtDetails.map((rt) {
                  final m = rt is Map ? rt : <String, dynamic>{};
                  // Normalize KK and Rumah with wider key support and fallbacks
                  final kk = _toInt(
                      m['kk'] ?? m['jumlah_kk'] ?? m['total_kk'] ?? m['kk_terdampak'] ?? m['jumlah_kk_terdampak'] ?? m['jumlah_keluarga'] ?? m['total_keluarga']);
                  final rumah = _toInt(
                      m['rumah'] ?? m['jumlah_rumah'] ?? m['total_rumah'] ?? m['rumah_terdampak'] ?? m['rumah_rusak'] ?? m['jumlah_rumah_terdampak']);
                  final jiwa = _toInt(m['jiwa'] ?? m['korban_jiwa'] ?? m['total_jiwa'] ?? m['jiwa_terdampak']);

                  return [
                    'RT ${m['rt_number'] ?? m['rt'] ?? ''}',
                    _formatNumber(kk),
                    _formatNumber(rumah),
                    _formatNumber(jiwa),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Data bantuan
            if (bantuan.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Bantuan',
                headers: ['Jenis Bantuan', 'Jumlah', 'Satuan'],
                rows: bantuan.entries.map((e) => [
                  _formatKey(e.key),
                  _formatNumber(e.value as int? ?? 0),
                  'Unit'
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Data penanganan
            if (penanganan.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Penanganan',
                headers: ['Jenis Penanganan', 'Status', 'Keterangan'],
                rows: penanganan.entries.map((e) => [
                  _formatKey(e.key),
                  e.value != null ? 'Tersedia' : 'Tidak Tersedia',
                  '-'
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            pw.SizedBox(height: 10),
          ],
        ),
      );

      await _savePdf(
        pdf,
        'Laporan_Kebencanaan_${desaName}_$year.pdf',
        context,
        desaName: desaName,
      );
    } catch (e) {
      _showError(context, 'Gagal membuat laporan kebencanaan: $e');
    }
  }

  // Helper methods
  static pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    required DateTime date,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            '${_formatDate(date)} ${_formatTime(date)}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Sistem Informasi Desa',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Halaman ${context.pageNumber}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoSection(String title, List<List<String>> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: data.map((row) => pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[0], style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          )).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: headers.map((header) => pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              )).toList(),
            ),
            // Data rows
            ...rows.map((row) => pw.TableRow(
              children: row.map((cell) => pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(cell, style: const pw.TextStyle(fontSize: 10)),
              )).toList(),
            )),
          ],
        ),
      ],
    );
  }

  // Notes removed per request; function intentionally omitted.

  static String _formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(number);
  }

  static String _formatPercentage(int value, int total) {
    if (total == 0) return '0.0%';
    final percentage = (value / total * 100);
    return '${percentage.toStringAsFixed(1)}%';
  }

  static String _formatKey(String key) {
    return key.replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? 
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : word)
        .join(' ');
  }

  // Expand common pendidikan abbreviations into readable labels.
  static String _expandPendidikanLabel(String key) {
    final mapping = <String, String>{
      'PAUD': 'PAUD (Pendidikan Anak Usia Dini)',
      'TK': 'TK (Taman Kanak-kanak)',
      'SD': 'Sekolah Dasar (SD)',
      'SMP': 'Sekolah Menengah Pertama (SMP)',
      'SMA': 'Sekolah Menengah Atas (SMA)',
      'SMK': 'Sekolah Menengah Kejuruan (SMK)',
      'AKADEMI/PT': 'Akademi / Perguruan Tinggi (Akademi/PT)',
      'AKADEMI': 'Akademi (Akademi)',
      'PT': 'Perguruan Tinggi (PT)',
      'SDLB': 'SD Luar Biasa (SDLB)',
      'SMPLB': 'SMP Luar Biasa (SMPLB)',
      'SMALB': 'SMA Luar Biasa (SMALB)',
      'TBM': 'TBM (Taman Bermain)',
    };

    final original = key.toString();
    final norm = original.trim();
    // Exact match first (case-insensitive)
    for (final k in mapping.keys) {
      if (norm.toUpperCase() == k) return mapping[k]!;
    }

    // If the key contains a known abbreviation as a separate word, replace it
    var result = original;
    for (final k in mapping.keys) {
      final re = RegExp(r'\b' + RegExp.escape(k) + r'\b', caseSensitive: false);
      if (re.hasMatch(result)) {
        result = result.replaceAll(re, mapping[k]!);
        return result;
      }
    }

    // Fallback: pretty format the key
    return _formatKey(original);
  }

  // Robust converter to int: accepts int, num, numeric strings, maps with common keys, or nested maps/lists.
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    if (v is Map) {
      // common keys that might hold counts
      for (final key in ['jumlah', 'total', 'nilai', 'value', 'count', 'jumlah_unit']) {
        if (v.containsKey(key)) return _toInt(v[key]);
      }
      // sum numeric-like values inside the map
      int sum = 0;
      for (final val in v.values) {
        sum += _toInt(val);
      }
      return sum;
    }
    if (v is Iterable) {
      int sum = 0;
      for (final item in v) sum += _toInt(item);
      return sum;
    }
    return 0;
  }

  // Normalize facility-like structures into Map<String,int>.
  // Accepts:
  // - Map<String, dynamic> where values are counts or nested maps
  // - List<Map> where each item may contain name and count fields
  // - Iterable of entries
  static Map<String, int> _normalizeFacilities(dynamic raw, List<String> defaults) {
    final Map<String, int> out = {};
    if (raw is Map) {
      for (final e in raw.entries) {
        out[e.key.toString()] = _toInt(e.value);
      }
    } else if (raw is Iterable) {
      for (final item in raw) {
        if (item is Map) {
          // try to detect name and count fields
          String? name;
          dynamic count;
          for (final k in ['jenis', 'nama', 'name', 'type', 'fasilitas']) {
            if (item.containsKey(k)) {
              name = item[k]?.toString();
              break;
            }
          }
          for (final k in ['jumlah', 'nilai', 'value', 'total', 'count', 'unit']) {
            if (item.containsKey(k)) {
              count = item[k];
              break;
            }
          }
          // fallback: if map has single string key -> treat as name with numeric value
          if (name == null && item.length == 1) {
            final e = item.entries.first;
            name = e.key.toString();
            count = e.value;
          }
          if (name != null) {
            out[name] = _toInt(count);
          } else {
            // try to flatten any numeric values inside the map into a summed count
            final summed = _toInt(item);
            if (summed > 0) {
              // generate a synthetic name to avoid key collision
              out['item_${out.length + 1}'] = summed;
            }
          }
        } else if (item is String) {
          out[item] = (out[item] ?? 0) + 1;
        } else if (item is num) {
          out['value_${out.length + 1}'] = _toInt(item);
        }
      }
    }

    // Ensure defaults exist
    for (final d in defaults) {
      out.putIfAbsent(d, () => 0);
    }

    return out;
  }

  static Future<void> _savePdf(
    pw.Document pdf,
    String filename,
    BuildContext context, {
    required String desaName,
  }) async {
    final bytes = await pdf.save();

    String sanitize(String input) => input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    try {
      Directory baseDir;

      if (Platform.isAndroid) {
        // Prefer the Downloads external directory on Android
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        baseDir = (dirs != null && dirs.isNotEmpty) ? dirs.first : await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        // iOS doesn't expose a Downloads folder; use app documents
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        // Desktop: use Downloads if available
        baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final folderName = 'Desa Cantik';
      final desaFolderName = sanitize(desaName);
      final targetDir = Directory('${baseDir.path}${Platform.pathSeparator}$folderName${Platform.pathSeparator}$desaFolderName');
      if (!await targetDir.exists()) await targetDir.create(recursive: true);

      final file = File('${targetDir.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => Printing.sharePdf(bytes: bytes, filename: filename),
            ),
          ),
        );
      }
    } catch (e) {
      // If saving fails (permissions, platform limitations), fallback to previous behavior
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          await Printing.sharePdf(bytes: bytes, filename: filename);
        } else {
          final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final file = File('${dir.path}${Platform.pathSeparator}$filename');
          await file.writeAsBytes(bytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF berhasil disimpan: ${file.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Buka',
                  onPressed: () => Printing.sharePdf(bytes: bytes, filename: filename),
                ),
              ),
            );
          }
        }
      } catch (e2) {
        _showError(context, 'Gagal menyimpan atau membagikan PDF: $e2');
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}