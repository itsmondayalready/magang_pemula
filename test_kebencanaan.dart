import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gcqxynheshjonedcnwbp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjcXh5bmhlc2hqb25lZGNud2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MjQ3OTMsImV4cCI6MjA3NzEwMDc5M30.QaSpMK4fa5-ILOgbCg1x1et_ZmcHOwYlCZw4Jn8JlVg',
  );

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Kebencanaan Data')),
        body: const TestWidget(),
      ),
    );
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  String _result = 'Loading...';

  @override
  void initState() {
    super.initState();
    _checkData();
  }

  Future<void> _checkData() async {
    final db = Supabase.instance.client;

    try {
      // Check kebencanaan_rekap data for 2025
      final result = await db
          .from('kebencanaan_rekap')
          .select('id, kode_wilayah, jenis, period_start, period_end, periode_date')
          .gte('period_end', '2025-01-01')
          .lt('period_end', '2026-01-01')
          .limit(10);

      setState(() {
        _result = 'Kebencanaan data for 2025: ${result.length} records\n';
        for (var row in result) {
          _result += '$row\n';
        }
      });

      // Check if any data exists at all
      final allData = await db
          .from('kebencanaan_rekap')
          .select('id, kode_wilayah, jenis, period_start, period_end')
          .limit(5);

      setState(() {
        _result += '\nTotal kebencanaan records: ${allData.length}\n';
        for (var row in allData) {
          _result += '$row\n';
        }
      });

    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(_result),
      ),
    );
  }
}