import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://gcqxynheshjonedcnwbp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjcXh5bmhlc2hqb25lZGNud2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MjQ3OTMsImV4cCI6MjA3NzEwMDc5M30.QaSpMK4fa5-ILOgbCg1x1et_ZmcHOwYlCZw4Jn8JlVg',
  );

  final db = Supabase.instance.client;

  try {
    // Check kebencanaan_rekap data for 2025
    final result = await db
        .from('kebencanaan_rekap')
        .select('id, kode_wilayah, jenis, period_start, period_end, periode_date')
        .gte('period_end', '2025-01-01')
        .lt('period_end', '2026-01-01')
        .limit(10);

    dev.log('Kebencanaan data for 2025: ${result.length} records');
    for (var row in result) {
      dev.log('Record: $row');
    }

    // Check if any data exists at all
    final allData = await db
        .from('kebencanaan_rekap')
        .select('id, kode_wilayah, jenis, period_start, period_end')
        .limit(5);

    dev.log('Total kebencanaan records: ${allData.length}');
    for (var row in allData) {
      dev.log('All records: $row');
    }

  } catch (e) {
    dev.log('Error checking data: $e');
  }
}