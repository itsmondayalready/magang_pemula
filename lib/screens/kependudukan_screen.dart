import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';
import '../services/kependudukan_repository.dart';
import '../services/auth_service.dart';

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
  bool _hasChanges = false; // Track if data was modified

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
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.isAdmin;
    
    return WillPopScope(
      onWillPop: () async {
        // Return the hasChanges flag when popping
        Navigator.of(context).pop(_hasChanges);
        return false; // Prevent default pop since we handle it manually
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _openEditBottomSheet,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0B7A75), // emerald
                      Color(0xFFB08900), // gold
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x400B7A75),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            )
          : null,
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

    // Tampilkan semua kategori meskipun nilainya 0 (seperti chart tenaga medis)
    final sortedEntries = educationOrder
        .map((k) => MapEntry(k, aggregated[k] ?? 0))
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

    // Show empty state if both values are 0 or null
    final hasData = bekerja > 0 || tidakBekerja > 0;

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
                    // Legend - 2 kolom responsive
                    LayoutBuilder(
                      builder: (context, legendConstraints) {
                        // Two columns untuk semua ukuran layar
                        final leftColumn = <Widget>[];
                        final rightColumn = <Widget>[];
                        
                        for (int i = 0; i < sortedEntries.length; i++) {
                          final entry = sortedEntries[i];
                          final item = _buildLegendItem(
                            color: _getPekerjaanColor(entry.key),
                            label: entry.key,
                            value: entry.value,
                          );
                          
                          if (i % 2 == 0) {
                            leftColumn.add(item);
                          } else {
                            rightColumn.add(item);
                          }
                        }
                        
                        // Pastikan kedua kolom punya jumlah item yang sama
                        // dengan menambah placeholder jika perlu
                        while (leftColumn.length > rightColumn.length) {
                          rightColumn.add(const SizedBox.shrink());
                        }
                        
                        // Build rows dengan IntrinsicHeight untuk tinggi sama
                        final rows = <Widget>[];
                        for (int i = 0; i < leftColumn.length; i++) {
                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: leftColumn[i]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: i < rightColumn.length
                                          ? rightColumn[i]
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return Column(children: rows);
                      },
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

  Future<void> _openEditBottomSheet() async {
    // Controllers untuk data header
    final totalPendudukCtl = TextEditingController(
      text: _totalPenduduk?.toString() ?? '0',
    );
    final totalKKCtl = TextEditingController(
      text: _totalKK?.toString() ?? '0',
    );
    final lakiLakiCtl = TextEditingController(
      text: _lakiLaki?.toString() ?? '0',
    );
    final perempuanCtl = TextEditingController(
      text: _perempuan?.toString() ?? '0',
    );
    final produktifBekerjaCtl = TextEditingController(
      text: _produktifBekerja?.toString() ?? '0',
    );
    final produktifTidakCtl = TextEditingController(
      text: _produktifTidak?.toString() ?? '0',
    );

    // Controllers untuk pendidikan
    final pendidikanControllers = <String, TextEditingController>{};
    final pendidikanCategories = [
      'Tidak Tamat SD',
      'Tamat SD',
      'Tamat SMP',
      'Tamat SMA',
      'Akademi/PT',
    ];
    for (final cat in pendidikanCategories) {
      pendidikanControllers[cat] = TextEditingController(
        text: (_pendidikan[cat] ?? 0).toString(),
      );
    }

    // Controllers untuk pekerjaan - buat list editable
    final pekerjaanItems = _pekerjaan.entries.map((e) {
      return _EditableItem(
        label: e.key,
        labelCtl: TextEditingController(text: e.key),
        valueCtl: TextEditingController(text: e.value.toString()),
      );
    }).toList();

    // Bisa tambah item baru
    if (pekerjaanItems.isEmpty) {
      pekerjaanItems.add(_EditableItem(
        label: 'Pekerjaan 1',
        labelCtl: TextEditingController(text: 'Pekerjaan 1'),
        valueCtl: TextEditingController(text: '0'),
      ));
    }

    if (!mounted) return;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _EditBottomSheet(
          totalPendudukCtl: totalPendudukCtl,
          totalKKCtl: totalKKCtl,
          lakiLakiCtl: lakiLakiCtl,
          perempuanCtl: perempuanCtl,
          produktifBekerjaCtl: produktifBekerjaCtl,
          produktifTidakCtl: produktifTidakCtl,
          pendidikanCategories: pendidikanCategories,
          pendidikanControllers: pendidikanControllers,
          pekerjaanItems: pekerjaanItems,
          repo: _repo,
          kodeWilayah: widget.kodeWilayah,
          onDataSaved: () async {
            // Mark that data has changed
            _hasChanges = true;
            
            // Refresh data di parent screen
            setState(() => _loading = true);
            await _load();
            setState(() => _loading = false);
          },
      ),
    ).then((_) {
      // Dispose controllers SETELAH bottom sheet ditutup
      // Gunakan addPostFrameCallback untuk memastikan semua frame selesai
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          totalPendudukCtl.dispose();
          totalKKCtl.dispose();
          lakiLakiCtl.dispose();
          perempuanCtl.dispose();
          produktifBekerjaCtl.dispose();
          produktifTidakCtl.dispose();
          for (final ctl in pendidikanControllers.values) {
            ctl.dispose();
          }
          for (final item in pekerjaanItems) {
            item.labelCtl.dispose();
            item.valueCtl.dispose();
          }
        } catch (e) {
          // Ignore disposal errors
          print('Controller disposal error (can be ignored): $e');
        }
      });
    });
    } catch (e) {
      // Catch any Flutter framework assertions
      print('ModalBottomSheet error (can be ignored if save works): $e');
    }
  }
}

// Helper class untuk editable items
class _EditableItem {
  final String label;
  final TextEditingController labelCtl;
  final TextEditingController valueCtl;

  _EditableItem({
    required this.label,
    required this.labelCtl,
    required this.valueCtl,
  });
}

// Bottom Sheet dengan TabBar untuk Edit
class _EditBottomSheet extends StatefulWidget {
  final TextEditingController totalPendudukCtl;
  final TextEditingController totalKKCtl;
  final TextEditingController lakiLakiCtl;
  final TextEditingController perempuanCtl;
  final TextEditingController produktifBekerjaCtl;
  final TextEditingController produktifTidakCtl;
  final List<String> pendidikanCategories;
  final Map<String, TextEditingController> pendidikanControllers;
  final List<_EditableItem> pekerjaanItems;
  final KependudukanRepository repo;
  final String kodeWilayah;
  final VoidCallback onDataSaved;

  const _EditBottomSheet({
    required this.totalPendudukCtl,
    required this.totalKKCtl,
    required this.lakiLakiCtl,
    required this.perempuanCtl,
    required this.produktifBekerjaCtl,
    required this.produktifTidakCtl,
    required this.pendidikanCategories,
    required this.pendidikanControllers,
    required this.pekerjaanItems,
    required this.repo,
    required this.kodeWilayah,
    required this.onDataSaved,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  @override
  Widget build(BuildContext context) {
    bool saving = false;
    
    return StatefulBuilder(
      builder: (context, setLocal) => DefaultTabController(
      length: 4,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                        colors: [Color(0xFF0B7A75), Color(0xFFB08900)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Edit Data Kependudukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perbarui informasi kependudukan desa',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Data Utama'),
                Tab(text: 'Pendidikan'),
                Tab(text: 'Produktivitas'),
                Tab(text: 'Pekerjaan'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDataUtamaTab(),
                  _buildPendidikanTab(),
                  _buildProduktivitasTab(),
                  _buildPekerjaanTab(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    setLocal(() => saving = true);
                    try {
                      // Validasi dan parse data utama
                      final totalPenduduk = int.tryParse(widget.totalPendudukCtl.text.trim());
                      final totalKK = int.tryParse(widget.totalKKCtl.text.trim());
                      final lakiLaki = int.tryParse(widget.lakiLakiCtl.text.trim());
                      final perempuan = int.tryParse(widget.perempuanCtl.text.trim());
                      final produktifBekerja =
                          int.tryParse(widget.produktifBekerjaCtl.text.trim());
                      final produktifTidak = int.tryParse(widget.produktifTidakCtl.text.trim());

                      if (totalPenduduk == null ||
                          totalKK == null ||
                          lakiLaki == null ||
                          perempuan == null ||
                          produktifBekerja == null ||
                          produktifTidak == null) {
                        if (!context.mounted) return;
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
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Validasi Gagal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Semua field data utama harus diisi dengan angka valid',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.fixed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      if (totalPenduduk < 0 ||
                          totalKK < 0 ||
                          lakiLaki < 0 ||
                          perempuan < 0 ||
                          produktifBekerja < 0 ||
                          produktifTidak < 0) {
                        if (!context.mounted) return;
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
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Input Tidak Valid',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Angka tidak boleh negatif',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFF59E0B),
                            behavior: SnackBarBehavior.fixed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      // Parse pendidikan
                      final pendidikanData = <String, int>{};
                      for (final entry in widget.pendidikanControllers.entries) {
                        final value = int.tryParse(entry.value.text.trim()) ?? 0;
                        if (value >= 0) {
                          pendidikanData[entry.key] = value;
                        }
                      }

                      // Parse pekerjaan
                      final pekerjaanData = <String, int>{};
                      for (final item in widget.pekerjaanItems) {
                        final label = item.labelCtl.text.trim();
                        final value = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                        if (label.isNotEmpty && value > 0) {
                          pekerjaanData[label] = value;
                        }
                      }

                      // Save to database
                      await widget.repo.upsertHeader(
                        kodeWilayah: widget.kodeWilayah,
                        totalPenduduk: totalPenduduk,
                        totalKK: totalKK,
                        lakiLaki: lakiLaki,
                        perempuan: perempuan,
                        produktifBekerja: produktifBekerja,
                        produktifTidak: produktifTidak,
                      );

                      await widget.repo.updatePendidikan(
                        kodeWilayah: widget.kodeWilayah,
                        pendidikanData: pendidikanData,
                      );

                      await widget.repo.updatePekerjaan(
                        kodeWilayah: widget.kodeWilayah,
                        pekerjaanData: pekerjaanData,
                      );

                      // Close bottom sheet
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        
                        // Call parent callback to refresh data
                        widget.onDataSaved();
                        
                        // Show success notification
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Berhasil!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Data kependudukan berhasil diperbarui',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.fixed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
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
                                    Icons.error_outline,
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
                                        'Gagal Menyimpan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$e',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.fixed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setLocal(() => saving = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B7A75), Color(0xFFB08900)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ), // DefaultTabController
    ); // StatefulBuilder
  }

  Widget _buildDataUtamaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField('Total KK', widget.totalKKCtl),
        _buildTextField('Laki-laki', widget.lakiLakiCtl),
        _buildTextField('Perempuan', widget.perempuanCtl),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total Penduduk dihitung otomatis dari Laki-laki + Perempuan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendidikanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: widget.pendidikanCategories
          .map((cat) =>
              _buildTextField(cat, widget.pendidikanControllers[cat]!))
          .toList(),
    );
  }

  Widget _buildProduktivitasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0B7A75).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF0B7A75),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data usia produktif (15-64 tahun)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildTextField('Produktif Bekerja', widget.produktifBekerjaCtl),
        _buildTextField('Produktif Tidak Bekerja', widget.produktifTidakCtl),
      ],
    );
  }

  Widget _buildPekerjaanTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Tambah padding bottom untuk button sticky
            children: [
              // List pekerjaan dengan row (label dan value berdampingan)
              ...widget.pekerjaanItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: item.labelCtl,
                              decoration: InputDecoration(
                                labelText: 'Jenis Pekerjaan',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0B7A75), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: item.valueCtl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Jumlah',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0B7A75), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hapus',
                        onPressed: () {
                          setState(() {
                            widget.pekerjaanItems.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        // Sticky button di bawah
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                widget.pekerjaanItems.add(_EditableItem(
                  label: '',
                  labelCtl: TextEditingController(),
                  valueCtl: TextEditingController(),
                ));
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Pekerjaan'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B7A75), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

