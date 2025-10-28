import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class KependudukanScreen extends StatefulWidget {
  const KependudukanScreen({super.key});

  @override
  State<KependudukanScreen> createState() => _KependudukanScreenState();
}

class _KependudukanScreenState extends State<KependudukanScreen>
    with SingleTickerProviderStateMixin {
  // Data dummy untuk visualisasi
  final Map<String, dynamic> _dataDummy = {
    'total_penduduk': 5234,
    'total_kk': 1247,
    'total_rt': 45,
    'total_rw': 9,
    'gender': {'laki_laki': 2630, 'perempuan': 2604},
    'kelompok_usia': {
      '0-4': 235,
      '5-9': 288,
      '10-14': 342,
      '15-19': 414,
      '20-24': 456,
      '25-29': 489,
      '30-34': 512,
      '35-39': 498,
      '40-44': 445,
      '45-49': 378,
      '50-54': 312,
      '55-59': 267,
      '60-64': 223,
      '65+': 375,
    },
    'pendidikan': {
      'Tidak Sekolah': 145,
      'SD': 1234,
      'SMP': 978,
      'SMA': 1456,
      'Diploma': 234,
      'Sarjana': 987,
      'Pascasarjana': 200,
    },
    'pekerjaan': {
      'Belum Bekerja': 456,
      'Pelajar': 890,
      'Petani': 1234,
      'Pedagang': 567,
      'PNS': 345,
      'Wiraswasta': 789,
      'Lainnya': 953,
    },
  };

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 64,
            title: const Text(
              'Kependudukan',
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
                    colors: [
                      Color(0xFF0B7A75), // emerald
                      Color(0xFFB08900), // gold
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Summary cards moved OUTSIDE AppBar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildSummaryCard(
                    label: 'Total Penduduk',
                    value: '${_dataDummy['total_penduduk']}',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF0B7A75),
                  ),
                  _buildSummaryCard(
                    label: 'Kepala Keluarga',
                    value: '${_dataDummy['total_kk']}',
                    icon: Icons.home_rounded,
                    color: const Color(0xFF1A8B85),
                  ),
                  _buildSummaryCard(
                    label: 'Rukun Tetangga',
                    value: '${_dataDummy['total_rt']}',
                    icon: Icons.location_city_rounded,
                    color: const Color(0xFF2A9C95),
                  ),
                  _buildSummaryCard(
                    label: 'Rukun Warga',
                    value: '${_dataDummy['total_rw']}',
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF0B7A75),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChartSection(_buildGenderChart()),
            _buildChartSection(_buildUsiaChart()),
            _buildChartSection(_buildPendidikanChart()),
            _buildChartSection(_buildPekerjaanChart()),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0B7A75),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF0B7A75),
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
              Tab(icon: Icon(Icons.wc_rounded, size: 20), text: 'Gender'),
              Tab(icon: Icon(Icons.cake_rounded, size: 20), text: 'Usia'),
              Tab(
                icon: Icon(Icons.school_rounded, size: 20),
                text: 'Pendidikan',
              ),
              Tab(icon: Icon(Icons.work_rounded, size: 20), text: 'Pekerjaan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(Widget chart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: chart,
      ),
    );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChart() {
    final genderData = _dataDummy['gender'] as Map<String, dynamic>;
    final lakiLaki = genderData['laki_laki'] as int;
    final perempuan = genderData['perempuan'] as int;
    final total = lakiLaki + perempuan;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B7A75).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wc_rounded,
                  color: Color(0xFF0B7A75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribusi Jenis Kelamin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Perbandingan penduduk berdasarkan gender',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  'Laki-laki',
                  lakiLaki,
                  total,
                  Icons.male_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  'Perempuan',
                  perempuan,
                  total,
                  Icons.female_rounded,
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 280,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 70,
                  sections: [
                    PieChartSectionData(
                      value: lakiLaki.toDouble(),
                      title: '${(lakiLaki / total * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFF3B82F6),
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: _buildBadge(
                        Icons.male_rounded,
                        const Color(0xFF3B82F6),
                      ),
                      badgePositionPercentageOffset: 1.3,
                    ),
                    PieChartSectionData(
                      value: perempuan.toDouble(),
                      title: '${(perempuan / total * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFFEC4899),
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: _buildBadge(
                        Icons.female_rounded,
                        const Color(0xFFEC4899),
                      ),
                      badgePositionPercentageOffset: 1.3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(
    String label,
    int value,
    int total,
    IconData icon,
    Color color,
  ) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildUsiaChart() {
    final usiaData = _dataDummy['kelompok_usia'] as Map<String, dynamic>;
    final maxValue = usiaData.values.cast<int>().reduce(
      (a, b) => a > b ? a : b,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B7A75).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cake_rounded,
                  color: Color(0xFF0B7A75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribusi Kelompok Usia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Piramida penduduk berdasarkan rentang usia',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 450,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxValue * 1.2).toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF0B7A75),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final kelompok = usiaData.keys.elementAt(group.x.toInt());
                      return BarTooltipItem(
                        '$kelompok tahun\n${rod.toY.toInt()} jiwa',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < usiaData.length) {
                          final kelompok = usiaData.keys.elementAt(
                            value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              kelompok,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: 100,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
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
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                barGroups: List.generate(usiaData.length, (index) {
                  final value = usiaData.values.elementAt(index) as int;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _getAgeColor(index),
                            _getAgeColor(index).withValues(alpha: 0.7),
                          ],
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendidikanChart() {
    final pendidikanData = _dataDummy['pendidikan'] as Map<String, dynamic>;
    final sortedEntries = pendidikanData.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final total = pendidikanData.values.cast<int>().reduce((a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B7A75).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF0B7A75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Tingkat Pendidikan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${total.toString()} penduduk',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...sortedEntries.map((entry) {
            final percentage = (entry.value as int) / total * 100;
            return _buildModernHorizontalBar(
              label: entry.key,
              value: entry.value as int,
              percentage: percentage,
              color: _getPendidikanColor(entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPekerjaanChart() {
    final pekerjaanData = _dataDummy['pekerjaan'] as Map<String, dynamic>;
    final total = pekerjaanData.values.cast<int>().reduce((a, b) => a + b);
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
    ];
    final sortedEntries = pekerjaanData.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B7A75).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Color(0xFF0B7A75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Jenis Pekerjaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${total.toString()} penduduk',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: List.generate(sortedEntries.length, (index) {
                    final entry = sortedEntries[index];
                    final value = entry.value as int;
                    final percentage = value / total * 100;
                    return PieChartSectionData(
                      value: value.toDouble(),
                      title: percentage > 8
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      color: colors[index % colors.length],
                      radius: 90,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final percentage = ((entry.value as int) / total * 100)
                  .toStringAsFixed(1);
              return _buildModernLegendItem(
                color: colors[index % colors.length],
                label: entry.key,
                value: entry.value as int,
                percentage: percentage,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernLegendItem({
    required Color color,
    required String label,
    required int value,
    required String percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$value ($percentage%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHorizontalBar({
    required String label,
    required int value,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAgeColor(int index) {
    final colors = [
      const Color(0xFF93C5FD),
      const Color(0xFF60A5FA),
      const Color(0xFF3B82F6),
      const Color(0xFF2563EB),
      const Color(0xFF1D4ED8),
      const Color(0xFF1E40AF),
      const Color(0xFF06B6D4),
      const Color(0xFF0891B2),
      const Color(0xFF14B8A6),
      const Color(0xFF0D9488),
      const Color(0xFF10B981),
      const Color(0xFF059669),
      const Color(0xFFF97316),
      const Color(0xFFEA580C),
    ];
    return colors[index % colors.length];
  }

  Color _getPendidikanColor(String pendidikan) {
    switch (pendidikan) {
      case 'Tidak Sekolah':
        return const Color(0xFFF87171);
      case 'SD':
        return const Color(0xFFFB923C);
      case 'SMP':
        return const Color(0xFFFBBF24);
      case 'SMA':
        return const Color(0xFF84CC16);
      case 'Diploma':
        return const Color(0xFF06B6D4);
      case 'Sarjana':
        return const Color(0xFF2563EB);
      case 'Pascasarjana':
        return const Color(0xFF4F46E5);
      default:
        return Colors.grey;
    }
  }
}
