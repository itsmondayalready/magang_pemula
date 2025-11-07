import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return Scaffold(
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
      ),
    );
  }

  Future<void> _load() async {
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

      final row = await _repo.fetchLatest(kode, jenis: 'banjir');
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
        });
      } else {
        setState(() {
          _dataBanjir = null; // tidak ada data
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
                              10,
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
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= top.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'RT ${top[idx].key}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
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
                                    width: 36,
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
