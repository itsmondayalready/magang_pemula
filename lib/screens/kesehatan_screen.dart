import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/responsive.dart';

class KesehatanScreen extends StatefulWidget {
  const KesehatanScreen({super.key});

  @override
  State<KesehatanScreen> createState() => _KesehatanScreenState();
}

class _KesehatanScreenState extends State<KesehatanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy breakdown data for UC-D01
  Map<String, dynamic> get _data => {
        'fasilitas': {
          'Rumah Sakit': 1,
          'Puskesmas': 2,
          'Poliklinik': 2,
          'Poskesdes': 3,
          'Posyandu': 12,
          'Apotek': 6,
        },
        'tenaga_medis': {
          'Dokter': 5,
          'Perawat': 12,
          'Bidan': 9,
          'Kader': 30,
        },
        'imunisasi': {
          'BCG': 120,
          'DPT': 200,
          'Polio': 180,
          'Campak/MR': 160,
          'Hepatitis B': 140,
        },
        'penyakit': {
          'ISPA': 90,
          'Diare': 75,
          'Hipertensi': 48,
          'Diabetes': 22,
          'DBD': 15,
          'Lainnya': 30,
        },
      };

  int _sum(Map<String, int> map) => map.values.fold(0, (p, c) => p + c);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
              'Kesehatan',
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
                      Color(0xFF06B6D4), // cyan
                      Color(0xFF1D4ED8), // blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: context.summaryAspect,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _SummaryCard(
                    label: 'Fasilitas',
                    value: _sum(Map<String, int>.from(_data['fasilitas']))
                        .toString(),
                    icon: Icons.local_hospital_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                  _SummaryCard(
                    label: 'Tenaga Medis',
                    value:
                        _sum(Map<String, int>.from(_data['tenaga_medis']))
                            .toString(),
                    icon: Icons.volunteer_activism_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _SummaryCard(
                    label: 'Imunisasi',
                    value: _sum(Map<String, int>.from(_data['imunisasi']))
                        .toString(),
                    icon: Icons.vaccines_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _SummaryCard(
                    label: 'Penyakit',
                    value: _sum(Map<String, int>.from(_data['penyakit']))
                        .toString(),
                    icon: Icons.sick_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSection(
              _Card(
                icon: Icons.local_hospital_rounded,
                title: 'Fasilitas Kesehatan',
                subtitle: 'Distribusi fasilitas layanan kesehatan per jenis',
                child: _FasilitasPie(
                  data: Map<String, int>.from(_data['fasilitas']),
                ),
              ),
            ),
            _buildSection(
              _Card(
                icon: Icons.volunteer_activism_rounded,
                title: 'Tenaga Medis',
                subtitle: 'Komposisi tenaga kesehatan per peran',
                child: _HorizontalBars(
                  data: Map<String, int>.from(_data['tenaga_medis']),
                  colorFor: (k) => const Color(0xFF10B981),
                ),
              ),
            ),
            _buildSection(
              _Card(
                icon: Icons.vaccines_rounded,
                title: 'Imunisasi',
                subtitle: 'Cakupan (dummy) per jenis imunisasi',
                child:
                    _ImunisasiBars(data: Map<String, int>.from(_data['imunisasi'])),
              ),
            ),
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
            labelColor: const Color(0xFF06B6D4),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF06B6D4),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            tabs: const [
              Tab(icon: Icon(Icons.local_hospital_rounded, size: 20), text: 'Fasilitas'),
              Tab(icon: Icon(Icons.volunteer_activism_rounded, size: 20), text: 'Tenaga'),
              Tab(icon: Icon(Icons.vaccines_rounded, size: 20), text: 'Imunisasi'),
            ],
          ),
        ),
      ),
    );
  }

  // Section wrapper for body tabs
  Widget _buildSection(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

// ---------- Common card container ----------
class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF06B6D4), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ---------- Fasilitas Pie Chart ----------
class _FasilitasPie extends StatelessWidget {
  const _FasilitasPie({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (p, c) => p + c);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 60,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final pct = total == 0 ? 0 : e.value / total * 100;
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: pct > 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    color: colors[i % colors.length],
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .asMap()
              .entries
              .map(
                (kv) => _legendItem(
                  color: colors[kv.key % colors.length],
                  label: kv.value.key,
                  value: kv.value.value,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ---------- Horizontal bars (Tenaga Medis, Penyakit) ----------
class _HorizontalBars extends StatelessWidget {
  const _HorizontalBars({required this.data, required this.colorFor});
  final Map<String, int> data;
  final Color Function(String key) colorFor;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (p, c) => p + c);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.asMap().entries.map((kv) {
          final e = kv.value;
          final color = colorFor(e.key);
          final double pct = total == 0 ? 0.0 : (e.value / total * 100.0);
          final isLast = kv.key == entries.length - 1;
          return _modernHorizontalBar(
            label: e.key,
            value: e.value,
            percentage: pct,
            color: color,
            bottomPadding: isLast ? 0 : 16,
          );
        }),
      ],
    );
  }
}

// ---------- Imunisasi vertical bars ----------
class _ImunisasiBars extends StatelessWidget {
  const _ImunisasiBars({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.fold<int>(0, (p, c) => c > p ? c : p);
    final keys = data.keys.toList();
    final values = data.values.map((e) => e.toDouble()).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxValue * 1.2).toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (g) => const Color(0xFFF59E0B),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (g, gi, rod, ri) {
                final label = keys[g.x.toInt()];
                return BarTooltipItem(
                  '$label\n${rod.toY.toInt()} dosis',
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
                reservedSize: 40,
                getTitlesWidget: (v, m) {
                  if (v.toInt() >= 0 && v.toInt() < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        keys[v.toInt()],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: (maxValue / 4).clamp(1, maxValue.toDouble()),
                getTitlesWidget: (v, m) => Text(
                  v.toInt().toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxValue / 4).clamp(1, maxValue.toDouble()),
            getDrawingHorizontalLine: (v) => FlLine(
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
          barGroups: List.generate(keys.length, (i) {
            final color = const Color(0xFFF59E0B);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.7)],
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
    );
  }
}

// ---------- Reusable bits ----------
Widget _legendItem({required Color color, required String label, required int value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label: $value', style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

Widget _modernHorizontalBar({
  required String label,
  required int value,
  required double percentage,
  required Color color,
  double bottomPadding = 16,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (percentage / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(widthFactor: value, child: child),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
