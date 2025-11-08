import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/responsive.dart';
import '../services/kependudukan_repository.dart';

class KependudukanScreen extends StatefulWidget {
  const KependudukanScreen({
    super.key,
    required this.kodeWilayah,
    required this.desaName,
  });

  final String kodeWilayah;
  final String desaName;

  @override
  State<KependudukanScreen> createState() => _KependudukanScreenState();
}

class _KependudukanScreenState extends State<KependudukanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = KependudukanRepository();
  bool _loading = true;

  // State data dari DB
  int? _totalPenduduk;
  int? _totalKK;
  int? _lakiLaki;
  int? _perempuan;
  int? _produktifBekerja;
  int? _produktifTidak;
  int? _totalUsiaProduktif;
  Map<String, int> _pendidikan = const {};
  Map<String, int> _pekerjaan = const {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
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
            headerSliverBuilder: (context, inner) => [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                toolbarHeight: 56,
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
                        label: 'Total Penduduk',
                        value: _totalPenduduk?.toString() ?? '—',
                        icon: Icons.people_rounded,
                        color: const Color(0xFF0B7A75),
                      ),
                      _buildSummaryCard(
                        label: 'Kepala Keluarga',
                        value: _totalKK?.toString() ?? '—',
                        icon: Icons.home_rounded,
                        color: const Color(0xFF1A8B85),
                      ),
                      // RT/RW tidak tersedia di header kependudukan; bisa diambil dari profil jika ingin
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
                  _buildChartSection(_buildGenderChart()),
                  _buildChartSection(_buildPendidikanChart()),
                  _buildChartSection(_buildPekerjaanChart()),
                  _buildChartSection(_buildDetailPekerjaanChart()),
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
              Tab(
                icon: Icon(Icons.school_rounded, size: 20),
                text: 'Pendidikan',
              ),
              Tab(
                icon: Icon(Icons.trending_up_rounded, size: 20),
                text: 'Produktivitas',
              ),
              Tab(icon: Icon(Icons.work_rounded, size: 20), text: 'Pekerjaan'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Timeout agar UI tidak mengunci lama saat jaringan lambat
      final headerFuture = _repo.fetchLatestHeader(widget.kodeWilayah);
      final pendidikanFuture = _repo.fetchPendidikanLatest(widget.kodeWilayah);
      final pekerjaanFuture = _repo.fetchPekerjaanLatest(widget.kodeWilayah);

      final results = await Future.wait([
        headerFuture,
        pendidikanFuture,
        pekerjaanFuture,
      ]).timeout(const Duration(seconds: 8));

      final headerObj = results[0];
      final pendidikan = results[1] as Map<String, int>;
      final pekerjaan = results[2] as Map<String, int>;

      // Debug logging
      print('=== KEPENDUDUKAN DEBUG ===');
      print('kodeWilayah: ${widget.kodeWilayah}');
      print('Header: $headerObj');
      print('Pendidikan raw: $pendidikan');
      print('Pekerjaan raw: $pekerjaan');
      print('========================');

      if (mounted) {
        setState(() {
          if (headerObj is Map) {
            final map = headerObj as Map;
            _totalPenduduk =
                (map['total_penduduk'] ?? map['total'] ?? 0) as int?;
            _totalKK = (map['total_kk'] ?? 0) as int?;
            _lakiLaki = (map['laki_laki'] ?? map['l'] ?? 0) as int?;
            _perempuan = (map['perempuan'] ?? map['p'] ?? 0) as int?;
            final bekerja = map['produktif_bekerja'] as int?;
            final tidak = map['produktif_tidak_bekerja'] as int?;
            _produktifBekerja = bekerja;
            _produktifTidak = tidak;
            if (bekerja != null && tidak != null) {
              _totalUsiaProduktif = bekerja + tidak;
            }
          }
          _pendidikan = pendidikan;
          _pekerjaan = pekerjaan;
        });
      }
    } catch (e) {
      print('Error loading kependudukan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildChartSection(Widget chart) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    maxLines: 1,
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

  Widget _buildGenderChart() {
    final lakiLaki = _lakiLaki ?? 0;
    final perempuan = _perempuan ?? 0;
    final total = (lakiLaki + perempuan).clamp(0, 1 << 31);

    // Only show notice if both values are null (no data from DB)
    final hasData = _lakiLaki != null || _perempuan != null;

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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wc_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribusi Gender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Perbandingan jumlah laki-laki dan perempuan',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data gender periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else ...[
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
                        title: total == 0
                            ? ''
                            : '${(lakiLaki / total * 100).toStringAsFixed(1)}%',
                        color: const Color(0xFF3B82F6),
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: perempuan.toDouble(),
                        title: total == 0
                            ? ''
                            : '${(perempuan / total * 100).toStringAsFixed(1)}%',
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
                        badgePositionPercentageOffset: 1.06,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildPendidikanChart() {
    final Map<String, int> pendidikanData = _pendidikan;

    // Normalisasi label dari DB ke 5 kategori tetap, lalu agregasi
    final Map<String, int> aggregated = {
      'Tidak Tamat SD': 0,
      'Tamat SD': 0,
      'Tamat SMP': 0,
      'Tamat SMA': 0,
      'Akademi/PT': 0,
    };
    for (final entry in pendidikanData.entries) {
      final normalized = _normalizeEduLabel(entry.key);
      if (normalized != null) {
        aggregated[normalized] = (aggregated[normalized] ?? 0) + entry.value;
      }
    }

    // Urutan dari rendah ke tinggi
    final educationOrder = [
      'Tidak Tamat SD',
      'Tamat SD',
      'Tamat SMP',
      'Tamat SMA',
      'Akademi/PT',
    ];

    final sortedEntries = educationOrder
        .map((k) => MapEntry(k, aggregated[k] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    final total = aggregated.values.isEmpty
        ? 0
        : aggregated.values.reduce((a, b) => a + b);

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
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Belum ada data pendidikan periode ini',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...sortedEntries.map((entry) {
            final int v = entry.value;
            final percentage = total == 0 ? 0.0 : v / total * 100;
            return _buildModernHorizontalBar(
              label: entry.key,
              value: v,
              percentage: percentage,
              color: _getPendidikanColor(entry.key),
            );
          }),
        ],
      ),
    );
  }

  // Pemetaan label bebas dari DB ke 5 kategori tetap
  String? _normalizeEduLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    // Tidak Tamat SD
    const notSd = {
      'tidak tamat sd',
      'belum tamat sd',
      'tidak sekolah',
      'belum sekolah',
    };
    if (notSd.contains(s)) return 'Tidak Tamat SD';

    // Tamat SD
    const sd = {'tamat sd', 'sd', 'sekolah dasar'};
    if (sd.contains(s)) return 'Tamat SD';

    // Tamat SMP
    const smp = {'tamat smp', 'smp', 'sekolah menengah pertama'};
    if (smp.contains(s)) return 'Tamat SMP';

    // Tamat SMA
    const sma = {
      'tamat sma',
      'sma',
      'smu',
      'smk',
      'ma',
      'sekolah menengah atas',
    };
    if (sma.contains(s)) return 'Tamat SMA';

    // Akademi/PT (Diploma/Sarjana/Pasca)
    const pt = {
      'akademi/pt',
      'akademi',
      'pt',
      'perguruan tinggi',
      'd1',
      'd2',
      'd3',
      'd4',
      'diploma',
      's1',
      's2',
      's3',
      'sarjana',
      'pascasarjana',
    };
    if (pt.contains(s)) return 'Akademi/PT';

    // Tidak dikenali -> null (abaikan)
    return null;
  }

  Widget _buildPekerjaanChart() {
    final bekerja = _produktifBekerja ?? 0;
    final tidakBekerja = _produktifTidak ?? 0;
    final totalUsiaProduktif = _totalUsiaProduktif ?? (bekerja + tidakBekerja);

    // Only show notice if data is null (no data from DB)
    final hasData = _produktifBekerja != null || _produktifTidak != null;

    final colors = [
      const Color(0xFF10B981), // Hijau untuk Bekerja
      const Color(0xFFEF4444), // Merah untuk Tidak Bekerja
    ];

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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${totalUsiaProduktif.toString()} orang',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data produktivitas periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            // Responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Column(
                  children: [
                    // Pie Chart
                    Center(
                      child: SizedBox(
                        height: isSmallScreen ? 250 : 300,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: isSmallScreen ? 60 : 70,
                            sections: [
                              PieChartSectionData(
                                value: bekerja.toDouble(),
                                title: totalUsiaProduktif == 0
                                    ? ''
                                    : '${(bekerja / totalUsiaProduktif * 100).toStringAsFixed(1)}%',
                                color: colors[0],
                                radius: isSmallScreen ? 80 : 90,
                                titleStyle: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: tidakBekerja.toDouble(),
                                title: totalUsiaProduktif == 0
                                    ? ''
                                    : '${(tidakBekerja / totalUsiaProduktif * 100).toStringAsFixed(1)}%',
                                color: colors[1],
                                radius: isSmallScreen ? 80 : 90,
                                titleStyle: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildProduktivitasCard(
                            label: 'Bekerja',
                            value: bekerja,
                            total: totalUsiaProduktif,
                            color: colors[0],
                            icon: Icons.work_rounded,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProduktivitasCard(
                            label: 'Tidak Bekerja',
                            value: tidakBekerja,
                            total: totalUsiaProduktif,
                            color: colors[1],
                            icon: Icons.person_off_rounded,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProduktivitasCard({
    required String label,
    required int value,
    required int total,
    required Color color,
    required IconData icon,
    bool isSmallScreen = false,
  }) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPekerjaanChart() {
    final Map<String, int> pekerjaanData = _pekerjaan;

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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Pekerjaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pekerjaanData.isEmpty
                          ? 'Distribusi jenis pekerjaan penduduk'
                          : 'Total: ${pekerjaanData.values.reduce((a, b) => a + b)} orang',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (pekerjaanData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data pekerjaan periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            // Data available - show chart
            LayoutBuilder(
              builder: (context, constraints) {
                final total = pekerjaanData.values.reduce((a, b) => a + b);
                // Urutan berdasarkan jumlah (dari terbesar ke terkecil)
                final sortedEntries = pekerjaanData.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                final isSmallScreen = constraints.maxWidth < 600;
                return Column(
                  children: [
                    Center(
                      child: SizedBox(
                        height: isSmallScreen ? 250 : 300,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: isSmallScreen ? 50 : 60,
                            sections: sortedEntries.asMap().entries.map((
                              entry,
                            ) {
                              final data = entry.value;
                              final value = data.value;
                              final percentage = total == 0
                                  ? 0.0
                                  : (value / total * 100);

                              return PieChartSectionData(
                                value: value.toDouble(),
                                title: percentage >= 5
                                    ? '${percentage.toStringAsFixed(1)}%'
                                    : '',
                                color: _getPekerjaanColor(data.key),
                                radius: isSmallScreen ? 70 : 80,
                                titleStyle: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    // Legend
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedEntries.map((entry) {
                        return _buildLegendItem(
                          color: _getPekerjaanColor(entry.key),
                          label: entry.key,
                          value: entry.value,
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$value orang',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPekerjaanColor(String pekerjaan) {
    // Palet warna yang lebih beragam dan kontras untuk setiap kategori pekerjaan
    final colorMap = <String, Color>{
      'Mengurus Rumah Tangga': const Color(0xFFEC4899), // Pink
      'Tidak atau Belum Bekerja': const Color(0xFFEF4444), // Red
      'Pelajar dan Mahasiswa': const Color(0xFF3B82F6), // Blue
      'Wiraswasta': const Color(0xFF10B981), // Green
      'Buruh Harian Lepas': const Color(0xFFF59E0B), // Amber
      'Pegawai Negeri Sipil (PNS)': const Color(0xFF8B5CF6), // Purple
      'Karyawan Swasta': const Color(0xFF06B6D4), // Cyan
      'Petani': const Color(0xFF84CC16), // Lime
      'Nelayan': const Color(0xFF0EA5E9), // Sky
      'Pedagang': const Color(0xFFF97316), // Orange
      'Buruh Tani': const Color(0xFFA3E635), // Light Green
      'Guru': const Color(0xFF6366F1), // Indigo
      'Bidan': const Color(0xFFDB2777), // Deep Pink
      'Perawat': const Color(0xFFE11D48), // Rose
      'Sopir': const Color(0xFF0891B2), // Dark Cyan
      'Tukang': const Color(0xFFEAB308), // Yellow
      'Lain-lainnya': const Color(0xFF6B7280), // Gray
    };

    // Jika nama pekerjaan ada di map, gunakan warna tersebut
    if (colorMap.containsKey(pekerjaan)) {
      return colorMap[pekerjaan]!;
    }

    // Jika tidak ada, generate warna unik berdasarkan hash string
    final hash = pekerjaan.hashCode;
    final r = ((hash & 0xFF0000) >> 16);
    final g = ((hash & 0x00FF00) >> 8);
    final b = (hash & 0x0000FF);

    // Pastikan warna cukup terang agar terlihat di chart
    final adjustedR = (r * 0.7 + 80).toInt().clamp(0, 255);
    final adjustedG = (g * 0.7 + 80).toInt().clamp(0, 255);
    final adjustedB = (b * 0.7 + 80).toInt().clamp(0, 255);

    return Color.fromARGB(255, adjustedR, adjustedG, adjustedB);
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

  Color _getPendidikanColor(String pendidikan) {
    switch (pendidikan) {
      case 'Tidak Tamat SD':
        return const Color(0xFFF87171); // merah
      case 'Tamat SD':
        return const Color(0xFFFB923C); // oranye
      case 'Tamat SMP':
        return const Color(0xFFFBBF24); // kuning
      case 'Tamat SMA':
        return const Color(0xFF84CC16); // hijau
      case 'Akademi/PT':
        return const Color(0xFF2563EB); // biru
      default:
        return Colors.grey;
    }
  }
}
