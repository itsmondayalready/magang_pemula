import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
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
            // Informasi umum
            _buildInfoSection('Informasi Umum', [
              ['Nama Desa', desaName],
              ['Kode Wilayah', kodeWilayah],
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),
            
            pw.SizedBox(height: 20),
            
            // Ringkasan demografis
            _buildInfoSection('Ringkasan Demografis', [
              ['Total Penduduk', _formatNumber(totalPenduduk) + ' jiwa'],
              ['Total Kepala Keluarga', _formatNumber(totalKK) + ' KK'],
              ['Rata-rata per KK', totalKK > 0 ? (totalPenduduk / totalKK).toStringAsFixed(1) + ' jiwa/KK' : '0 jiwa/KK'],
            ]),
            
            pw.SizedBox(height: 20),
            
            // Data berdasarkan jenis kelamin
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
            
            // Data berdasarkan kelompok usia
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
            
            // Catatan
            _buildNotes([
              'Data berdasarkan pencatatan terbaru pada tahun $year',
              'Laporan ini dibuat secara otomatis oleh sistem',
              'Untuk verifikasi data, hubungi petugas pendataan desa',
            ]),
          ],
        ),
      );

      await _savePdf(pdf, 'Laporan_Kependudukan_${desaName}_$year.pdf', context);
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
      
      final totalFasilitas = (data['total_fasilitas'] ?? 0) as int;
      final totalTenagaMedis = (data['total_tenaga_medis'] ?? 0) as int;
      final puskesmas = (data['puskesmas'] ?? 0) as int;
      final polindes = (data['polindes'] ?? 0) as int;
      final posyandu = (data['posyandu'] ?? 0) as int;
      final dokter = (data['dokter'] ?? 0) as int;
      final bidan = (data['bidan'] ?? 0) as int;
      final perawat = (data['perawat'] ?? 0) as int;
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
              headers: ['Jenis Fasilitas', 'Jumlah', 'Persentase'],
              rows: [
                ['Puskesmas', _formatNumber(puskesmas), _formatPercentage(puskesmas, totalFasilitas)],
                ['Polindes', _formatNumber(polindes), _formatPercentage(polindes, totalFasilitas)],
                ['Posyandu', _formatNumber(posyandu), _formatPercentage(posyandu, totalFasilitas)],
                ['Total', _formatNumber(totalFasilitas), '100.0%'],
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            _buildDataTable(
              title: 'Data Tenaga Medis',
              headers: ['Jenis Tenaga', 'Jumlah', 'Persentase'],
              rows: [
                ['Dokter', _formatNumber(dokter), _formatPercentage(dokter, totalTenagaMedis)],
                ['Bidan', _formatNumber(bidan), _formatPercentage(bidan, totalTenagaMedis)],
                ['Perawat', _formatNumber(perawat), _formatPercentage(perawat, totalTenagaMedis)],
                ['Total', _formatNumber(totalTenagaMedis), '100.0%'],
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            _buildNotes([
              'Data fasilitas dan tenaga kesehatan berdasarkan pencatatan tahun $year',
              'Laporan ini dibuat secara otomatis oleh sistem',
              'Untuk informasi lebih lanjut hubungi Dinas Kesehatan setempat',
            ]),
          ],
        ),
      );

      await _savePdf(pdf, 'Laporan_Kesehatan_${desaName}_$year.pdf', context);
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
      final year = (data['year'] ?? now.year) as int;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            title: 'LAPORAN INFRASTRUKTUR & PENDIDIKAN',
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
                  _formatKey(e.key),
                  _formatNumber(e.value as int? ?? 0),
                  'Sekolah'
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            
            pw.SizedBox(height: 10),
            
            _buildNotes([
              'Data infrastruktur dan pendidikan berdasarkan pencatatan tahun $year',
              'Data mencakup fasilitas yang ada dan berfungsi',
              'Laporan ini dibuat secara otomatis oleh sistem',
            ]),
          ],
        ),
      );

      await _savePdf(pdf, 'Laporan_Infrastruktur_${desaName}_$year.pdf', context);
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
      final year = (data['year'] ?? now.year) as int;

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
              ['Tahun Data', year.toString()],
              ['Tanggal Laporan', _formatDate(now)],
            ]),
            
            pw.SizedBox(height: 20),
            
            // Data rekap kebencanaan
            if (rekap.isNotEmpty) ...[
              _buildInfoSection('Rekap Kebencanaan', [
                ['Total Kejadian', _formatNumber(rekap['total_kejadian'] as int? ?? 0)],
                ['Rumah Rusak Ringan', _formatNumber(rekap['rusak_ringan'] as int? ?? 0)],
                ['Rumah Rusak Sedang', _formatNumber(rekap['rusak_sedang'] as int? ?? 0)],
                ['Rumah Rusak Berat', _formatNumber(rekap['rusak_berat'] as int? ?? 0)],
                ['Korban Jiwa', _formatNumber(rekap['korban_jiwa'] as int? ?? 0)],
                ['Korban Hilang', _formatNumber(rekap['korban_hilang'] as int? ?? 0)],
                ['Korban Luka', _formatNumber(rekap['korban_luka'] as int? ?? 0)],
                ['Mengungsi', _formatNumber(rekap['mengungsi'] as int? ?? 0)],
              ]),
              pw.SizedBox(height: 20),
            ],
            
            // Data per RT
            if (rtDetails.isNotEmpty) ...[
              _buildDataTable(
                title: 'Data Kebencanaan per RT',
                headers: ['RT', 'Rusak Ringan', 'Rusak Sedang', 'Rusak Berat', 'Korban'],
                rows: rtDetails.map((rt) => [
                  'RT ${rt['rt_number'] ?? ''}',
                  _formatNumber(rt['rusak_ringan'] as int? ?? 0),
                  _formatNumber(rt['rusak_sedang'] as int? ?? 0),
                  _formatNumber(rt['rusak_berat'] as int? ?? 0),
                  _formatNumber(rt['korban_jiwa'] as int? ?? 0),
                ]).toList(),
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
            
            _buildNotes([
              'Data kebencanaan berdasarkan pencatatan tahun $year',
              'Data mencakup semua kejadian bencana yang tercatat',
              'Laporan ini dibuat secara otomatis oleh sistem',
              'Untuk verifikasi data hubungi BPBD setempat',
            ]),
          ],
        ),
      );

      await _savePdf(pdf, 'Laporan_Kebencanaan_${desaName}_$year.pdf', context);
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

  static pw.Widget _buildNotes(List<String> notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Catatan:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...notes.map((note) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
              pw.Expanded(
                child: pw.Text(note, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        )),
      ],
    );
  }

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

  static Future<void> _savePdf(pw.Document pdf, String filename, BuildContext context) async {
    try {
      final bytes = await pdf.save();
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: langsung share/print
        await Printing.sharePdf(bytes: bytes, filename: filename);
      } else {
        // Desktop: simpan ke file
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
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
    } catch (e) {
      _showError(context, 'Gagal menyimpan PDF: $e');
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