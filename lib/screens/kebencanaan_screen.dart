import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/kebencanaan_repository.dart';
import '../utils/responsive.dart';

class KebencanaanScreen extends StatefulWidget {
  const KebencanaanScreen({super.key});

  @override
  State<KebencanaanScreen> createState() => _KebencanaanScreenState();
}

class _KebencanaanScreenState extends State<KebencanaanScreen>
    with SingleTickerProviderStateMixin {
  final _repo = KebencanaanRepository();
  // Null berarti: belum ada data (atau belum selesai dimuat)
  Map<String, dynamic>? _dataBanjir;
  bool _loading = false;
  String? _kodeWilayah; // simpan kode untuk kebutuhan edit
  bool _hasChanges = false; // Track if data has been modified

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load data dari Supabase (fallback ke sample jika kosong)
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    return WillPopScope(
      onWillPop: () async {
        // Return the hasChanges flag when popping
        Navigator.of(context).pop(_hasChanges);
        return false; // Prevent default pop since we handle it manually
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  toolbarHeight: 56,
                  title: const Text(
                    'Data Kebencanaan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  centerTitle: false,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  flexibleSpace: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      0,
                      context.horizontalPadding,
                      8,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: context.gridCount(
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                      childAspectRatio: context.summaryAspect,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildSummaryCard(
                          label: 'Rumah',
                          value: _fmtInt(_dataBanjir?['total_rumah']),
                          icon: Icons.home_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                        _buildSummaryCard(
                          label: 'Kepala Keluarga',
                          value: _fmtInt(_dataBanjir?['total_kk']),
                          icon: Icons.people_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                        _buildSummaryCard(
                          label: 'Jiwa Terdampak',
                          value: _fmtInt(_dataBanjir?['total_jiwa']),
                          icon: Icons.person_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                        _buildSummaryCard(
                          label: 'Kelompok Rentan',
                          value: _fmtInt(
                            ((_dataBanjir?['lansia'] ?? 0) as int) +
                                ((_dataBanjir?['bumil'] ?? 0) as int) +
                                ((_dataBanjir?['balita'] ?? 0) as int),
                            allowZero: true,
                          ),
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              body: Padding(
                padding: EdgeInsets.zero,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatistik(),
                    _buildPerRT(),
                    _buildBantuan(),
                    _buildPenanganan(),
                  ],
                ),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: _openEditKebencanaanSheet,
                backgroundColor: const Color(0xFFDC2626),
                child: const Icon(Icons.edit, color: Colors.white),
              )
            : null,
        bottomNavigationBar: Material(
          color: Colors.white,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFDC2626),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFDC2626),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 20),
                  text: 'Statistik',
                ),
                Tab(
                  icon: Icon(Icons.location_city_rounded, size: 20),
                  text: 'Per RT',
                ),
                Tab(
                  icon: Icon(Icons.volunteer_activism_rounded, size: 20),
                  text: 'Bantuan',
                ),
                Tab(
                  icon: Icon(Icons.engineering_rounded, size: 20),
                  text: 'Penanganan',
                ),
              ],
            ),
          ),
        ), // End bottomNavigationBar
      ), // End Scaffold
    ); // End WillPopScope
  }

  void _openEditKebencanaanSheet() {
    if (_kodeWilayah == null) return;
    final snapshotId =
        _dataBanjir?['snapshot_id'] as String?; // bisa null (insert baru)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KebencanaanEditSheet(
        kodeWilayah: _kodeWilayah!,
        snapshotId: snapshotId,
        initialData: _dataBanjir,
        onSaved: (String savedSnapshotId) async {
          if (!mounted) return;
          _hasChanges = true; // Mark that data has been modified
          setState(() => _loading = true);
          await _load(forceSnapshotId: savedSnapshotId);
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
  }

  // class continues with other methods below
  Future<void> _load({String? forceSnapshotId}) async {
    try {
      if (mounted) setState(() => _loading = true);
      // Ambil kode wilayah dari route args atau SharedPreferences
      String? kode;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        kode = (args['kodeWilayah'] as String?)?.trim();
      }
      if (kode == null || kode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        kode = prefs.getString('last_desa_kode');
      }
      kode ??= '6303052009';
      debugPrint('[Kebencanaan] Memuat data untuk kode_wilayah: ' + kode);

      Map<String, dynamic>? row;
      if (forceSnapshotId != null) {
        row = await _repo.fetchBySnapshotId(forceSnapshotId);
        // Jika fetch by id gagal (hapus atau id tidak ditemukan), fallback ke latest
        row ??= await _repo.fetchLatest(kode, jenis: 'banjir');
      } else {
        row = await _repo.fetchLatest(kode, jenis: 'banjir');
      }
      if (!mounted) return;
      if (row != null) {
        final mapped = _repo.toScreenData(row);
        // Gunakan 'jenis' asli dari DB jika tersedia (bantuan_raw dari skema normalized),
        // jika tidak ada gunakan heuristik dari nama seperti sebelumnya.
        List<Map<String, dynamic>> bantuanList;
        final bantuanRaw = List<Map<String, dynamic>>.from(
          (mapped['bantuan_raw'] ?? const []) as List,
        );
        if (bantuanRaw.isNotEmpty) {
          bantuanList = bantuanRaw
              .map(
                (b) => {
                  'nama': (b['nama'] ?? '').toString(),
                  'jenis': (b['jenis'] ?? '-').toString(),
                  'jumlah': '${b['jumlah'] ?? 0} unit',
                },
              )
              .toList();
        } else {
          final bantuanMap = Map<String, dynamic>.from(mapped['bantuan'] ?? {});
          bantuanList = bantuanMap.entries
              .map(
                (e) => {
                  'nama': e.key,
                  'jenis': (e.key.toString().toLowerCase().contains('tenda'))
                      ? 'Tenda'
                      : (e.key.toString().toLowerCase().contains('sembako'))
                      ? 'Sembako'
                      : '-',
                  'jumlah': '${e.value} unit',
                },
              )
              .toList();
        }

        setState(() {
          _dataBanjir = {...mapped, 'bantuan': bantuanList};
          _kodeWilayah = kode; // simpan untuk edit
        });
      } else {
        setState(() {
          _dataBanjir = null; // tidak ada data
          _kodeWilayah = kode;
        });
      }
    } catch (e) {
      debugPrint('Error load kebencanaan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.rs(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.rs(10),
            offset: Offset(0, context.rs(4)),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.rs(8)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(context.rs(10)),
              ),
              child: Icon(icon, color: color, size: context.rs(22)),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontSize: context.rf(22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(2)),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistik() {
    // Ambil data RT dinamis (maks 5 item untuk grafik)
    final rtMap = (_dataBanjir?['rt'] as Map<String, dynamic>?) ?? const {};
    final rtEntries =
        rtMap.entries
            .map(
              (e) => MapEntry(
                e.key.toString(),
                Map<String, dynamic>.from(e.value as Map),
              ),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final top = rtEntries.take(5).toList();

    final hasData = _dataBanjir != null && top.isNotEmpty;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: const Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      const Text(
                        'Jumlah Jiwa Terdampak Per RT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!hasData)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Belum ada data grafik per RT periode ini',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              top
                                  .map(
                                    (e) => ((e.value['jiwa'] ?? 0) as num)
                                        .toDouble(),
                                  )
                                  .fold<double>(0, (p, c) => c > p ? c : p) +
                              20,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.black87,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${rod.toY.toInt()} Jiwa',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= top.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'RT ${top[idx].key}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 50,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            for (int i = 0; i < top.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: ((top[i].value['jiwa'] ?? 0) as num)
                                        .toDouble(),
                                    gradient: LinearGradient(
                                      colors: i % 3 == 0
                                          ? [
                                              Colors.orange.shade400,
                                              Colors.orange.shade700,
                                            ]
                                          : i % 3 == 1
                                          ? [
                                              Colors.red.shade400,
                                              Colors.red.shade700,
                                            ]
                                          : [
                                              Colors.deepOrange.shade400,
                                              Colors.deepOrange.shade700,
                                            ],
                                    ),
                                    width: 28,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: const Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      const Text(
                        'Distribusi Kelompok Rentan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_dataBanjir == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Belum ada data kelompok rentan periode ini',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: [
                            PieChartSectionData(
                              value: (((_dataBanjir?['lansia'] ?? 0) as num)
                                  .toDouble()),
                              title: '${_dataBanjir?['lansia'] ?? 0}',
                              color: Colors.red.shade400,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: (((_dataBanjir?['bumil'] ?? 0) as num)
                                  .toDouble()),
                              title: '${_dataBanjir?['bumil'] ?? 0}',
                              color: Colors.purple.shade400,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: (((_dataBanjir?['balita'] ?? 0) as num)
                                  .toDouble()),
                              title: '${_dataBanjir?['balita'] ?? 0}',
                              color: Colors.blue.shade400,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildLegend(
                        'Lansia',
                        Colors.red.shade400,
                        (_dataBanjir?['lansia'] ?? 0) as int,
                      ),
                      _buildLegend(
                        'Ibu Hamil',
                        Colors.purple.shade400,
                        (_dataBanjir?['bumil'] ?? 0) as int,
                      ),
                      _buildLegend(
                        'Balita',
                        Colors.blue.shade400,
                        (_dataBanjir?['balita'] ?? 0) as int,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPerRT() {
    final rtData = (_dataBanjir?['rt'] as Map<String, dynamic>?) ?? const {};
    if (rtData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Belum ada data per RT periode ini',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_work, color: const Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      const Text(
                        'Perbandingan Rumah Per RT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...rtData.entries.map((e) {
                    final data = e.value as Map<String, dynamic>;
                    final maxRumah = 60;
                    final percentage = (data['rumah'] / maxRumah);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RT ${e.key}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${data['rumah']} Rumah',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              e.key == '001'
                                  ? Colors.orange
                                  : e.key == '002'
                                  ? Colors.red
                                  : Colors.deepOrange,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...rtData.entries.map((e) {
            final data = e.value as Map<String, dynamic>;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      e.key == '001'
                          ? Colors.orange.shade50
                          : e.key == '002'
                          ? Colors.red.shade50
                          : Colors.deepOrange.shade50,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: e.key == '001'
                                  ? Colors.orange
                                  : e.key == '002'
                                  ? Colors.red
                                  : Colors.deepOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'RT ${e.key}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.people,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data['jiwa']} Jiwa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRTStat(
                              Icons.home_outlined,
                              'Rumah',
                              '${data['rumah']}',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRTStat(
                              Icons.family_restroom,
                              'KK',
                              '${data['kk']}',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rentan: ${data['lansia']} Lansia, ${data['bumil']} Bumil, ${data['balita']} Balita, ${data['bayi']} Bayi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRTStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBantuan() {
    final bantuanList = (_dataBanjir?['bantuan'] as List<dynamic>?) ?? const [];
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Distribusi Jenis Bantuan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (bantuanList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Belum ada data bantuan periode ini',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: Builder(
                        builder: (_) {
                          final Map<String, int> jenisCount = {};
                          for (final b in bantuanList) {
                            final jenis = (b['jenis'] ?? '-').toString();
                            jenisCount[jenis] = (jenisCount[jenis] ?? 0) + 1;
                          }
                          final entries = jenisCount.entries.toList();
                          final colors = [
                            Colors.green.shade400,
                            Colors.teal.shade400,
                            Colors.cyan.shade400,
                            Colors.lightGreen.shade400,
                            Colors.blueGrey.shade400,
                          ];
                          return PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                for (int i = 0; i < entries.length; i++)
                                  PieChartSectionData(
                                    value: entries[i].value.toDouble(),
                                    title: entries[i].key,
                                    color: colors[i % colors.length],
                                    radius: 70,
                                    titleStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (bantuanList.isEmpty)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belum ada daftar bantuan tercatat',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...bantuanList.asMap().entries.map((entry) {
              final index = entry.key;
              final b = entry.value;
              final colors = [Colors.green, Colors.teal, Colors.cyan];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [colors[index].shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors[index].shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        index == 0
                            ? Icons.shopping_basket
                            : index == 1
                            ? Icons.home_repair_service
                            : Icons.medical_services,
                        color: colors[index].shade700,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      b['nama'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Jenis: ${b['jenis']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Jumlah: ${b['jumlah']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPenanganan() {
    final penangananList =
        (_dataBanjir?['penanganan'] as List<dynamic>?) ?? const [];
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.indigo.shade400],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.engineering,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upaya Penanganan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          penangananList.isEmpty
                              ? 'Belum ada kegiatan penanganan tercatat'
                              : 'Kegiatan pemulihan dan mitigasi bencana',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (penangananList.isEmpty)
            Center(
              child: Text(
                'Belum ada data penanganan periode ini',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...penangananList.asMap().entries.map((entry) {
              final index = entry.key;
              final isLast = index == penangananList.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.indigo.shade400,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade200,
                                    Colors.indigo.shade200,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade400,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          if (penangananList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFFDC2626)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total ${penangananList.length} kegiatan penanganan telah dilaksanakan',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Format helper: null -> '—', int -> string; optionally allow zero
  String _fmtInt(dynamic v, {bool allowZero = false}) {
    if (v == null) return '—';
    if (v is int) {
      if (v == 0 && !allowZero && _dataBanjir == null) return '—';
      return v.toString();
    }
    if (v is num) {
      final vi = v.toInt();
      if (vi == 0 && !allowZero && _dataBanjir == null) return '—';
      return vi.toString();
    }
    return v.toString();
  }
}

// ================= Bottom sheet edit widget (refactored) =================
class _KebencanaanEditSheet extends StatefulWidget {
  final String kodeWilayah;
  final String? snapshotId; // null kalau insert baru
  final Map<String, dynamic>? initialData;
  final Future<void> Function(String snapshotId) onSaved;
  const _KebencanaanEditSheet({
    Key? key,
    required this.kodeWilayah,
    required this.snapshotId,
    required this.initialData,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_KebencanaanEditSheet> createState() => _KebencanaanEditSheetState();
}

class _KebencanaanEditSheetState extends State<_KebencanaanEditSheet> {
  final formKey = GlobalKey<FormState>();
  bool saving = false;
  late final KebencanaanRepository _repo;

  // Statistik controllers
  late final TextEditingController totalRumahCtl;
  late final TextEditingController totalKkCtl;
  late final TextEditingController totalJiwaCtl;
  late final TextEditingController lansiaCtl;
  late final TextEditingController bumilCtl;
  late final TextEditingController balitaCtl;
  late final TextEditingController periodeLabelCtl;

  final List<_RtEditItem> rtItems = [];
  final List<_BantuanEditItem> bantuanItems = [];
  final List<_PenangananEditItem> penItems = [];

  @override
  void initState() {
    super.initState();
    _repo = KebencanaanRepository();
    final d = widget.initialData;
    totalRumahCtl = TextEditingController(
      text: (d?['total_rumah'] ?? 0).toString(),
    );
    totalKkCtl = TextEditingController(text: (d?['total_kk'] ?? 0).toString());
    totalJiwaCtl = TextEditingController(
      text: (d?['total_jiwa'] ?? 0).toString(),
    );
    lansiaCtl = TextEditingController(text: (d?['lansia'] ?? 0).toString());
    bumilCtl = TextEditingController(text: (d?['bumil'] ?? 0).toString());
    balitaCtl = TextEditingController(text: (d?['balita'] ?? 0).toString());
    periodeLabelCtl = TextEditingController(
      text: (d?['periode'] ?? '').toString(),
    );

    final rtMap = (d?['rt'] as Map<String, dynamic>?) ?? const {};
    for (final e in rtMap.entries) {
      final m = Map<String, dynamic>.from(e.value as Map);
      rtItems.add(
        _RtEditItem(
          rtCodeCtl: TextEditingController(text: e.key),
          rumahCtl: TextEditingController(text: (m['rumah'] ?? 0).toString()),
          kkCtl: TextEditingController(text: (m['kk'] ?? 0).toString()),
          jiwaCtl: TextEditingController(text: (m['jiwa'] ?? 0).toString()),
          lansiaCtl: TextEditingController(text: (m['lansia'] ?? 0).toString()),
          bumilCtl: TextEditingController(text: (m['bumil'] ?? 0).toString()),
          balitaCtl: TextEditingController(text: (m['balita'] ?? 0).toString()),
          bayiCtl: TextEditingController(text: (m['bayi'] ?? 0).toString()),
        ),
      );
    }
    // Jangan tambahkan item default jika tidak ada data
    // Biarkan user menambahkan sendiri dengan tombol "Tambah RT"

    final bantuanRaw = d?['bantuan_raw'];
    final List<Map<String, dynamic>> bantuanSource;

    if (bantuanRaw != null && bantuanRaw is List && bantuanRaw.isNotEmpty) {
      // If bantuan_raw exists and is a list, use it
      bantuanSource = List<Map<String, dynamic>>.from(
        bantuanRaw.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } else if (d != null && d['bantuan'] != null && d['bantuan'] is Map) {
      // If bantuan exists as a Map, convert it
      bantuanSource = Map<String, dynamic>.from(d['bantuan'] as Map).entries
          .map((e) => {'nama': e.key, 'jenis': '-', 'jumlah': e.value})
          .toList();
    } else {
      // No data, use empty list
      bantuanSource = [];
    }

    for (final b in bantuanSource) {
      bantuanItems.add(
        _BantuanEditItem(
          namaCtl: TextEditingController(text: b['nama']?.toString() ?? ''),
          jenisCtl: TextEditingController(text: b['jenis']?.toString() ?? ''),
          jumlahCtl: TextEditingController(text: (b['jumlah'] ?? 0).toString()),
        ),
      );
    }
    // Jangan tambahkan item default jika tidak ada data
    // Biarkan user menambahkan sendiri dengan tombol "Tambah Bantuan"

    final penList = List<String>.from((d?['penanganan'] ?? const []) as List);
    for (final e in penList.asMap().entries) {
      penItems.add(
        _PenangananEditItem(
          urutan: e.key + 1,
          deskripsiCtl: TextEditingController(text: e.value),
        ),
      );
    }
    // Jangan tambahkan item default jika tidak ada data
    // Biarkan user menambahkan sendiri dengan tombol "Tambah Penanganan"
  }

  @override
  void dispose() {
    totalRumahCtl.dispose();
    totalKkCtl.dispose();
    totalJiwaCtl.dispose();
    lansiaCtl.dispose();
    bumilCtl.dispose();
    balitaCtl.dispose();
    periodeLabelCtl.dispose();
    for (final it in rtItems) {
      it.rtCodeCtl.dispose();
      it.rumahCtl.dispose();
      it.kkCtl.dispose();
      it.jiwaCtl.dispose();
      it.lansiaCtl.dispose();
      it.bumilCtl.dispose();
      it.balitaCtl.dispose();
      it.bayiCtl.dispose();
    }
    for (final b in bantuanItems) {
      b.namaCtl.dispose();
      b.jenisCtl.dispose();
      b.jumlahCtl.dispose();
    }
    for (final p in penItems) {
      p.deskripsiCtl.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    isDense: true,
  );
  Widget _numField(String label, TextEditingController ctl) => TextFormField(
    controller: ctl,
    decoration: _dec(label),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (v) {
      if (v == null || v.trim().isEmpty) return null;
      return int.tryParse(v.trim()) == null ? 'Harus angka positif' : null;
    },
  );

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final totalRumah = int.tryParse(totalRumahCtl.text.trim()) ?? 0;
      final totalKk = int.tryParse(totalKkCtl.text.trim()) ?? 0;
      final totalJiwa = int.tryParse(totalJiwaCtl.text.trim()) ?? 0;
      final lansia = int.tryParse(lansiaCtl.text.trim()) ?? 0;
      final bumil = int.tryParse(bumilCtl.text.trim()) ?? 0;
      final balita = int.tryParse(balitaCtl.text.trim()) ?? 0;

      // Validasi: Jangan simpan jika semua nilai 0 dan tidak ada detail
      final hasMainData =
          totalRumah > 0 ||
          totalKk > 0 ||
          totalJiwa > 0 ||
          lansia > 0 ||
          bumil > 0 ||
          balita > 0;
      final hasRtData = rtItems.any(
        (item) => !item.removed && item.rtCodeCtl.text.trim().isNotEmpty,
      );
      final hasBantuanData = bantuanItems.any(
        (item) => !item.removed && item.namaCtl.text.trim().isNotEmpty,
      );
      final hasPenangananData = penItems.any(
        (item) => !item.removed && item.deskripsiCtl.text.trim().isNotEmpty,
      );

      if (!hasMainData && !hasRtData && !hasBantuanData && !hasPenangananData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada data yang perlu disimpan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => saving = false);
        return;
      }

      final snapId = await _repo.upsertRekap(
        snapshotId: widget.snapshotId,
        kodeWilayah: widget.kodeWilayah,
        jenis: 'banjir',
        periodeLabel: periodeLabelCtl.text.trim(),
        totalRumah: totalRumah,
        totalKk: totalKk,
        totalJiwa: totalJiwa,
        lansia: lansia,
        bumil: bumil,
        balita: balita,
      );
      if (snapId == null) throw Exception('Gagal menyimpan rekap');
      final isNormalized = await _repo.supportsNormalized();
      if (isNormalized) {
        // Replace mode: clear all detail rows for this snapshot, then insert current items
        await _repo.clearRtDetails(snapId);
        for (final it in rtItems.where((e) => !e.removed)) {
          final code = it.rtCodeCtl.text.trim();
          if (code.isEmpty) continue;
          await _repo.upsertRtDetail(
            snapshotId: snapId,
            rtCode: code,
            rumah: int.tryParse(it.rumahCtl.text.trim()) ?? 0,
            kk: int.tryParse(it.kkCtl.text.trim()) ?? 0,
            jiwa: int.tryParse(it.jiwaCtl.text.trim()) ?? 0,
            lansia: int.tryParse(it.lansiaCtl.text.trim()) ?? 0,
            bumil: int.tryParse(it.bumilCtl.text.trim()) ?? 0,
            balita: int.tryParse(it.balitaCtl.text.trim()) ?? 0,
            bayi: int.tryParse(it.bayiCtl.text.trim()) ?? 0,
          );
        }

        await _repo.clearBantuan(snapId);
        for (final b in bantuanItems.where((e) => !e.removed)) {
          final nama = b.namaCtl.text.trim();
          if (nama.isEmpty) continue;
          await _repo.upsertBantuan(
            snapshotId: snapId,
            nama: nama,
            jenis: b.jenisCtl.text.trim(),
            jumlah: int.tryParse(b.jumlahCtl.text.trim()) ?? 0,
          );
        }

        await _repo.clearPenanganan(snapId);
        for (final p in penItems.where((e) => !e.removed)) {
          final desc = p.deskripsiCtl.text.trim();
          if (desc.isEmpty) continue;
          await _repo.upsertPenanganan(
            snapshotId: snapId,
            urutan: p.urutan,
            deskripsi: desc,
          );
        }
      } else {
        final Map<String, dynamic> rtDetail = {};
        for (final it in rtItems) {
          if (it.removed) continue;
          final code = it.rtCodeCtl.text.trim();
          if (code.isEmpty) continue;
          rtDetail[code] = {
            'rumah': int.tryParse(it.rumahCtl.text.trim()) ?? 0,
            'kk': int.tryParse(it.kkCtl.text.trim()) ?? 0,
            'jiwa': int.tryParse(it.jiwaCtl.text.trim()) ?? 0,
            'lansia': int.tryParse(it.lansiaCtl.text.trim()) ?? 0,
            'bumil': int.tryParse(it.bumilCtl.text.trim()) ?? 0,
            'balita': int.tryParse(it.balitaCtl.text.trim()) ?? 0,
            'bayi': int.tryParse(it.bayiCtl.text.trim()) ?? 0,
          };
        }
        final Map<String, int> bantuanMap = {};
        for (final b in bantuanItems) {
          if (b.removed) continue;
          final nama = b.namaCtl.text.trim();
          if (nama.isEmpty) continue;
          bantuanMap[nama] = int.tryParse(b.jumlahCtl.text.trim()) ?? 0;
        }
        final List<dynamic> penanganan = [];
        for (final p in penItems) {
          if (p.removed) continue;
          final desc = p.deskripsiCtl.text.trim();
          if (desc.isEmpty) continue;
          penanganan.add(desc);
        }
        await _repo.updateLegacyDetails(
          kebencanaanId: snapId,
          rtDetail: rtDetail,
          bantuan: bantuanMap,
          penanganan: penanganan,
        );
      }
      await widget.onSaved(snapId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Berhasil!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data kebencanaan berhasil disimpan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header dengan garis dekoratif
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Edit Data Kebencanaan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perbarui rekap, RT, bantuan & penanganan',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Statistik'),
                          Tab(text: 'Per RT'),
                          Tab(text: 'Bantuan'),
                          Tab(text: 'Penanganan'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Statistik (improved spacing & 2-column layout)
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                24,
                              ),
                              children: [
                                const Text(
                                  'Statistik Rekap',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField(
                                        'Total Rumah',
                                        totalRumahCtl,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField('Total KK', totalKkCtl),
                                    ),
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField(
                                        'Total Jiwa',
                                        totalJiwaCtl,
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField('Lansia', lansiaCtl),
                                    ),
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField('Ibu Hamil', bumilCtl),
                                    ),
                                    SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              20 * 2 -
                                              16) /
                                          2,
                                      child: _numField('Balita', balitaCtl),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: periodeLabelCtl,
                                  decoration: _dec('Label Periode (opsional)'),
                                ),
                              ],
                            ),
                            // Per RT
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...rtItems
                                    .where((it) => !it.removed)
                                    .map(
                                      (it) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Card(
                                          elevation: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller:
                                                            it.rtCodeCtl,
                                                        decoration: _dec(
                                                          'RT Code',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly,
                                                        ],
                                                        validator: (v) =>
                                                            v == null ||
                                                                v.trim().isEmpty
                                                            ? 'Wajib'
                                                            : null,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Hapus RT',
                                                      onPressed: () => setState(
                                                        () => it.removed = true,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    SizedBox(
                                                      width: 100,
                                                      child: _numField(
                                                        'Rumah',
                                                        it.rumahCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 80,
                                                      child: _numField(
                                                        'KK',
                                                        it.kkCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Jiwa',
                                                        it.jiwaCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Lansia',
                                                        it.lansiaCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Bumil',
                                                        it.bumilCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Balita',
                                                        it.balitaCtl,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Bayi',
                                                        it.bayiCtl,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(
                                      () => rtItems.add(
                                        _RtEditItem(
                                          rtCodeCtl: TextEditingController(
                                            text: '00${rtItems.length + 1}',
                                          ),
                                          rumahCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          kkCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          jiwaCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          lansiaCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          bumilCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          balitaCtl: TextEditingController(
                                            text: '0',
                                          ),
                                          bayiCtl: TextEditingController(
                                            text: '0',
                                          ),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah RT'),
                                  ),
                                ),
                              ],
                            ),
                            // Bantuan
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...bantuanItems
                                    .where((b) => !b.removed)
                                    .map(
                                      (b) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Card(
                                          elevation: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller: b.namaCtl,
                                                        decoration: _dec(
                                                          'Nama Bantuan',
                                                        ),
                                                        validator: (v) =>
                                                            v == null ||
                                                                v.trim().isEmpty
                                                            ? 'Wajib'
                                                            : null,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => setState(
                                                        () => b.removed = true,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller: b.jenisCtl,
                                                        decoration: _dec(
                                                          'Jenis (opsional)',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 90,
                                                      child: _numField(
                                                        'Jumlah',
                                                        b.jumlahCtl,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(
                                      () => bantuanItems.add(
                                        _BantuanEditItem(
                                          namaCtl: TextEditingController(),
                                          jenisCtl: TextEditingController(),
                                          jumlahCtl: TextEditingController(
                                            text: '0',
                                          ),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Bantuan'),
                                  ),
                                ),
                              ],
                            ),
                            // Penanganan
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...penItems
                                    .where((p) => !p.removed)
                                    .map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Card(
                                          elevation: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.blue.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Langkah ${p.urutan}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      onPressed: () => setState(
                                                        () => p.removed = true,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: p.deskripsiCtl,
                                                  maxLines: 3,
                                                  decoration: _dec(
                                                    'Deskripsi Kegiatan',
                                                  ),
                                                  validator: (v) =>
                                                      v == null ||
                                                          v.trim().isEmpty
                                                      ? 'Wajib'
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() {
                                      final next =
                                          penItems
                                              .where((e) => !e.removed)
                                              .length +
                                          1;
                                      penItems.add(
                                        _PenangananEditItem(
                                          urutan: next,
                                          deskripsiCtl: TextEditingController(),
                                        ),
                                      );
                                    }),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Penanganan'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Helper model classes for edit sheet =================
class _RtEditItem {
  final TextEditingController rtCodeCtl;
  final TextEditingController rumahCtl;
  final TextEditingController kkCtl;
  final TextEditingController jiwaCtl;
  final TextEditingController lansiaCtl;
  final TextEditingController bumilCtl;
  final TextEditingController balitaCtl;
  final TextEditingController bayiCtl;
  bool removed = false;

  _RtEditItem({
    required this.rtCodeCtl,
    required this.rumahCtl,
    required this.kkCtl,
    required this.jiwaCtl,
    required this.lansiaCtl,
    required this.bumilCtl,
    required this.balitaCtl,
    required this.bayiCtl,
  });
}

class _BantuanEditItem {
  final TextEditingController namaCtl;
  final TextEditingController jenisCtl;
  final TextEditingController jumlahCtl;
  bool removed = false;

  _BantuanEditItem({
    required this.namaCtl,
    required this.jenisCtl,
    required this.jumlahCtl,
  });
}

class _PenangananEditItem {
  final int urutan;
  final TextEditingController deskripsiCtl;
  bool removed = false;
  _PenangananEditItem({required this.urutan, required this.deskripsiCtl});
}
