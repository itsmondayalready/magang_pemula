import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/responsive.dart';
import '../services/kesehatan_repository.dart';

class KesehatanScreen extends StatefulWidget {
  const KesehatanScreen({
    super.key,
    required this.kodeWilayah,
    required this.desaName,
  });

  final String kodeWilayah;
  final String desaName;

  @override
  State<KesehatanScreen> createState() => _KesehatanScreenState();
}

class _KesehatanScreenState extends State<KesehatanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = KesehatanRepository();
  bool _loading = true;

  // State data dari DB
  int? _totalFasilitas;
  int? _totalTenagaMedis;
  Map<String, int> _fasilitas = {};
  Map<String, int> _tenagaMedis = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repo
          .fetchLatest(widget.kodeWilayah)
          .timeout(const Duration(seconds: 8));

      print('=== KESEHATAN DEBUG ===');
      print('kodeWilayah: ${widget.kodeWilayah}');
      print('Data: $result');
      print('======================');

      if (mounted) {
        setState(() {
          if (result != null) {
            _totalFasilitas = (result['total_fasilitas'] ?? 0) as int?;
            _totalTenagaMedis = (result['total_tenaga_medis'] ?? 0) as int?;
            _fasilitas = _repo.extractFasilitas(result);
            _tenagaMedis = _repo.extractTenagaMedis(result);
          }
        });
      }
    } catch (e) {
      print('Error loading kesehatan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      _SummaryCard(
                        label: 'Fasilitas',
                        value: _totalFasilitas?.toString() ?? '—',
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFF06B6D4),
                      ),
                      _SummaryCard(
                        label: 'Tenaga Medis',
                        value: _totalTenagaMedis?.toString() ?? '—',
                        icon: Icons.volunteer_activism_rounded,
                        color: const Color(0xFF06B6D4),
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
                  _buildChartSection(
                    _Card(
                      icon: Icons.local_hospital_rounded,
                      title: 'Fasilitas Kesehatan',
                      subtitle:
                          'Distribusi fasilitas layanan kesehatan per jenis',
                      child: _FasilitasPie(data: _fasilitas),
                    ),
                  ),
                  _buildChartSection(
                    _Card(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Tenaga Medis',
                      subtitle: 'Komposisi tenaga kesehatan per peran',
                      child: _HorizontalBars(
                        data: _tenagaMedis,
                        colorFor: (k) => const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.18),
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
            labelColor: const Color(0xFF06B6D4),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF06B6D4),
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
                icon: Icon(Icons.local_hospital_rounded, size: 20),
                text: 'Fasilitas',
              ),
              Tab(
                icon: Icon(Icons.volunteer_activism_rounded, size: 20),
                text: 'Tenaga',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section wrapper for body tabs
  Widget _buildChartSection(Widget child) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        borderRadius: BorderRadius.circular(context.rs(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: context.rs(10),
            offset: Offset(0, context.rs(4)),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.rs(8)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
    // Check if data is empty (show notice only if no data structure exists)
    final hasData = data.isNotEmpty;

    if (!hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Belum ada data fasilitas kesehatan periode ini',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final total = data.values.fold(0, (p, c) => p + c);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Warna untuk kategori yang memiliki nilai > 0
    final activeColors = [
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF8B5CF6),
    ];

    // Warna abu-abu untuk kategori yang bernilai 0
    const greyColor = Color(0xFFE5E7EB);

    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final hasValue = e.value > 0;
                  final pct = total == 0 ? 0 : e.value / total * 100;

                  return PieChartSectionData(
                    value: hasValue
                        ? e.value.toDouble()
                        : 0.1, // Minimal value untuk tampil di chart
                    title: (hasValue && pct > 8)
                        ? '${pct.toStringAsFixed(0)}%'
                        : '',
                    color: hasValue
                        ? activeColors[i % activeColors.length]
                        : greyColor,
                    radius: hasValue
                        ? 90
                        : 85, // Sedikit lebih kecil untuk nilai 0
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
        const SizedBox(height: 20),
        // Tampilkan SEMUA legenda dengan jumlahnya dalam grid 2 kolom responsif
        Column(
          children: [
            for (int i = 0; i < entries.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _legendItemRow(
                        color: entries[i].value > 0
                            ? activeColors[i % activeColors.length]
                            : greyColor,
                        label: entries[i].key,
                        value: entries[i].value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (i + 1 < entries.length)
                      Expanded(
                        child: _legendItemRow(
                          color: entries[i + 1].value > 0
                              ? activeColors[(i + 1) % activeColors.length]
                              : greyColor,
                          label: entries[i + 1].key,
                          value: entries[i + 1].value,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
          ],
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
    // Check if data is empty (show notice only if no data structure exists)
    final hasData = data.isNotEmpty;

    if (!hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Belum ada data tenaga medis periode ini',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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

// ---------- Reusable bits ----------
Widget _legendItemRow({
  required Color color,
  required String label,
  required int value,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Responsif: sesuaikan ukuran berdasarkan lebar container
      final isCompact = constraints.maxWidth < 150;
      final circleSize = isCompact ? 10.0 : 12.0;
      final fontSize = isCompact
          ? 12.0
          : 13.0; // Ukuran font lebih besar agar tetap readable
      final horizontalPadding = isCompact ? 8.0 : 12.0;
      final verticalPadding = isCompact ? 8.0 : 10.0;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Align center untuk multi-line
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            SizedBox(width: isCompact ? 6 : 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                  height: 1.2, // Line height agar tidak terlalu rapat
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Izinkan 2 baris untuk teks panjang
              ),
            ),
            SizedBox(width: isCompact ? 4 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: fontSize,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
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
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                // Minimal 2% untuk nilai 0 agar tetap terlihat
                end: value == 0 ? 0.02 : (percentage / 100).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, child) =>
                  FractionallySizedBox(widthFactor: animValue, child: child),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: value == 0
                        ? [Colors.grey[300]!, Colors.grey[200]!]
                        : [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: value == 0
                      ? null
                      : [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: value > 0
                    ? Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
