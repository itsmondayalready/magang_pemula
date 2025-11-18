import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../utils/responsive.dart';
import '../services/kesehatan_repository.dart';
import '../services/auth_service.dart';

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
  bool _hasChanges = false; // Track if data was modified

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
                        Color(0xFF06B6D4), // cyan
                        Color(0xFF1D4ED8), // blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4006B6D4),
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

  Future<void> _openEditBottomSheet() async {
    // Controllers untuk fasilitas
    final fasilitasControllers = <String, TextEditingController>{};
    final fasilitasCategories = [
      'Rumah Sakit',
      'Puskesmas',
      'Poliklinik',
      'Tempat Praktik Dokter',
      'Tempat Praktik Bidan',
      'Poskesdes',
      'Polindes',
      'Apotek',
      'Posyandu',
      'Posbindu',
    ];
    for (final cat in fasilitasCategories) {
      fasilitasControllers[cat] = TextEditingController(
        text: (_fasilitas[cat] ?? 0).toString(),
      );
    }

    // Controllers untuk tenaga medis
    final tenagaMedisControllers = <String, TextEditingController>{};
    final tenagaMedisCategories = [
      'Kader KB/KIA',
      'Dokter Pria',
      'Dokter Wanita',
      'Dokter Gigi',
      'Bidan',
      'Perawat',
      'Tenaga Kesehatan Lain',
    ];
    for (final cat in tenagaMedisCategories) {
      tenagaMedisControllers[cat] = TextEditingController(
        text: (_tenagaMedis[cat] ?? 0).toString(),
      );
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
          fasilitasCategories: fasilitasCategories,
          fasilitasControllers: fasilitasControllers,
          tenagaMedisCategories: tenagaMedisCategories,
          tenagaMedisControllers: tenagaMedisControllers,
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            for (final ctl in fasilitasControllers.values) {
              ctl.dispose();
            }
            for (final ctl in tenagaMedisControllers.values) {
              ctl.dispose();
            }
          } catch (e) {
            print('Controller disposal error (can be ignored): $e');
          }
        });
      });
    } catch (e) {
      print('ModalBottomSheet error (can be ignored if save works): $e');
    }
  }
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
    // Hanya tampilkan kategori yang ada di data (termasuk yang bernilai 0)
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

    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                // Hanya tampilkan section yang nilainya > 0 di pie chart
                sections: entries
                    .asMap()
                    .entries
                    .where((mapEntry) => mapEntry.value.value > 0)
                    .map((mapEntry) {
                  final i = mapEntry.key;
                  final e = mapEntry.value;
                  final pct = total == 0 ? 0 : e.value / total * 100;

                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: pct > 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    color: activeColors[i % activeColors.length],
                    radius: 90,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Tampilkan legenda hanya untuk kategori dengan nilai >= 1
        Column(
          children: [
            for (int i = 0; i < entries.length; i += 2)
              if (entries[i].value >= 1 || (i + 1 < entries.length && entries[i + 1].value >= 1))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      if (entries[i].value >= 1)
                        Expanded(
                          child: _legendItemRow(
                            color: activeColors[i % activeColors.length],
                            label: entries[i].key,
                            value: entries[i].value,
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      const SizedBox(width: 8),
                      if (i + 1 < entries.length && entries[i + 1].value >= 1)
                        Expanded(
                          child: _legendItemRow(
                            color: activeColors[(i + 1) % activeColors.length],
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

// Bottom Sheet untuk Edit Kesehatan
class _EditBottomSheet extends StatefulWidget {
  final List<String> fasilitasCategories;
  final Map<String, TextEditingController> fasilitasControllers;
  final List<String> tenagaMedisCategories;
  final Map<String, TextEditingController> tenagaMedisControllers;
  final KesehatanRepository repo;
  final String kodeWilayah;
  final VoidCallback onDataSaved;

  const _EditBottomSheet({
    required this.fasilitasCategories,
    required this.fasilitasControllers,
    required this.tenagaMedisCategories,
    required this.tenagaMedisControllers,
    required this.repo,
    required this.kodeWilayah,
    required this.onDataSaved,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}
class _EditableMetric {
  _EditableMetric({required this.label, required String value, this.fromPreload = false})
      : valueCtl = TextEditingController(text: value),
        focusNode = FocusNode();

  final String label;
  final TextEditingController valueCtl;
  // mark if this item originated from preloaded DB values
  final bool fromPreload;
  // focus node so we can detect when editing finishes
  final FocusNode focusNode;
  bool removed = false;

  void dispose() {
    try {
      valueCtl.dispose();
    } catch (_) {}
    try {
      focusNode.dispose();
    } catch (_) {}
  }
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  // track saving state to show spinner and disable button
  bool _saving = false;
  // Editable lists for both categories (only items the user added / existing non-zero)
  final List<_EditableMetric> _fasilitasItems = [];
  final List<_EditableMetric> _tenagaItems = [];

  // Track which labels are currently added (to disable their chip)
  final Set<String> _addedFasilitas = {};
  final Set<String> _addedTenaga = {};
  // Track which labels the user marked for deletion (persist as 0 on save)
  final Set<String> _removedFasilitas = {};
  final Set<String> _removedTenaga = {};

  // Per-field inline errors keyed by a unique id (we'll use controller hash)
  final Map<int, String?> _fieldErrors = {};

  // Track controllers that we created so we can dispose safely
  final List<TextEditingController> _ownedControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize lists from incoming categories/controllers
    // Preload only entries that have a non-zero value to avoid clutter.
    for (final cat in widget.fasilitasCategories) {
      final ctl = widget.fasilitasControllers[cat];
      final text = ctl != null ? ctl.text.trim() : '';
      final v = int.tryParse(text) ?? 0;
      if (v > 0) {
        final item = _EditableMetric(label: cat, value: text, fromPreload: true);
        _fasilitasItems.add(item);
        _ownedControllers.add(item.valueCtl);
        _addedFasilitas.add(cat);
        // attach focus listener to mark deletion only when focus is lost
        _attachFocusHandler(item, _fasilitasItems, _addedFasilitas, true);
      }
    }
    for (final cat in widget.tenagaMedisCategories) {
      final ctl = widget.tenagaMedisControllers[cat];
      final text = ctl != null ? ctl.text.trim() : '';
      final v = int.tryParse(text) ?? 0;
      if (v > 0) {
        final item = _EditableMetric(label: cat, value: text, fromPreload: true);
        _tenagaItems.add(item);
        _ownedControllers.add(item.valueCtl);
        _addedTenaga.add(cat);
        // attach focus listener to mark deletion only when focus is lost
        _attachFocusHandler(item, _tenagaItems, _addedTenaga, false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ownedControllers) {
      try {
        c.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  void _validateNumeric(TextEditingController ctl) {
    final key = ctl.hashCode;
    final v = ctl.text.trim();
    if (v.isEmpty) {
      if (_fieldErrors[key] != null) setState(() => _fieldErrors[key] = null);
      return;
    }
      // Disallow comma, dot, minus and require digits only
      if (v.contains(',') || v.contains('.') || v.contains('-') || !RegExp(r'^\d+$').hasMatch(v)) {
      // Note: we will use a simple digits-only check when saving; show inline error
      setState(() => _fieldErrors[key] = 'Inputan tidak valid');
    } else {
      if (_fieldErrors[key] != null) setState(() => _fieldErrors[key] = null);
    }
  }

  void _onFieldChanged(List<_EditableMetric> list, Set<String> addedSet, _EditableMetric item, String val, bool isFasilitas) {
    // Validate current value only. Deletion will be handled when focus is lost.
    _validateNumeric(item.valueCtl);
  }

  void _attachFocusHandler(_EditableMetric item, List<_EditableMetric> list, Set<String> addedSet, bool isFasilitas) {
    // Avoid adding multiple listeners
    item.focusNode.addListener(() {
      if (!item.focusNode.hasFocus) {
        final v = item.valueCtl.text.trim();
        if (v.isEmpty && item.fromPreload) {
          // mark as removed and remove from UI
          setState(() {
            if (isFasilitas) {
              _removedFasilitas.add(item.label);
            } else {
              _removedTenaga.add(item.label);
            }
            final idx = list.indexOf(item);
            if (idx != -1) list.removeAt(idx);
            addedSet.remove(item.label);
            try {
              _ownedControllers.remove(item.valueCtl);
              item.dispose();
            } catch (_) {}
          });
          // Note: do NOT show per-delete snackbars here. We collect deletions
          // and will show a single combined notification when the user saves.
        }
      }
    });
  }

  bool _hasAnyValidationErrors() {
    // check label non-empty and numeric fields contain digits
    for (final item in [..._fasilitasItems, ..._tenagaItems]) {
      if (item.removed) continue;
  final label = item.label.trim();
      final value = item.valueCtl.text.trim();
      if (label.isEmpty) return true;
      if (value.isEmpty) return true;
        if (!RegExp(r'^\d+$').hasMatch(value)) return true;
    }
    // also check per-field inline errors
    if (_fieldErrors.values.any((e) => e != null)) return true;
    return false;
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);

    // If there are inline field errors, close sheet then show a small warning snackbar
    if (_fieldErrors.values.any((e) => e != null)) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perbaiki input yang tidak valid'),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 2),
          ),
        );
      }
      if (mounted) setState(() => _saving = false);
      return;
    }

    // check other validation (empty or non-digit)
    if (_hasAnyValidationErrors()) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
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
                        'Ada input kosong atau tidak valid',
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
      }
      if (mounted) setState(() => _saving = false);
      return;
    }

    // build maps
    final fasilitas = <String, int>{};
    final tenaga = <String, int>{};
    for (final it in _fasilitasItems) {
      if (it.removed) continue;
      final label = it.label.trim();
      final value = int.tryParse(it.valueCtl.text.trim()) ?? 0;
      fasilitas[label] = value;
    }
    for (final it in _tenagaItems) {
      if (it.removed) continue;
      final label = it.label.trim();
      final value = int.tryParse(it.valueCtl.text.trim()) ?? 0;
      tenaga[label] = value;
    }

    // Include any labels the user marked for deletion — persist as 0
    for (final removed in _removedFasilitas) {
      fasilitas[removed] = 0;
    }
    for (final removed in _removedTenaga) {
      tenaga[removed] = 0;
    }

    try {
      await widget.repo.upsertKesehatan(
        kodeWilayah: widget.kodeWilayah,
        fasilitasData: fasilitas,
        tenagaMedisData: tenaga,
      );

      // notify parent to refresh
      widget.onDataSaved();

      if (mounted) {
        // Build a combined deletion summary (if any) to show in one SnackBar
        final deletedLabels = [..._removedFasilitas, ..._removedTenaga];
        Navigator.of(context).pop();
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
                      const Text(
                        'Data kesehatan berhasil disimpan',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (deletedLabels.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Kategori dihapus: ${deletedLabels.join(', ')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onDeleteItem(List<_EditableMetric> list, Set<String> addedSet, _EditableMetric item, bool isFasilitas) async {
    // Mark the item as deleted locally; persist deletion on Save only.
    setState(() {
      if (isFasilitas) {
        _removedFasilitas.add(item.label);
      } else {
        _removedTenaga.add(item.label);
      }
      final idx = list.indexOf(item);
      if (idx != -1) list.removeAt(idx);
      addedSet.remove(item.label);
      try {
        _ownedControllers.remove(item.valueCtl);
        item.dispose();
      } catch (_) {}
    });
    // Do not show immediate SnackBar here; deletion will be summarized on Save.
  }

  Widget _buildListTab(List<_EditableMetric> list, List<String> allCategories, bool isFasilitas) {
    final addedSet = isFasilitas ? _addedFasilitas : _addedTenaga;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Added items list (show first so new items appear at top)
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Belum ada ${isFasilitas ? "fasilitas" : "tenaga medis"}', style: const TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      if (item.removed) return const SizedBox.shrink();
                      return Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(item.label),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: item.valueCtl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (val) => _onFieldChanged(list, addedSet, item, val, isFasilitas),
                              decoration: InputDecoration(
                                labelText: 'Jumlah',
                                errorText: _fieldErrors[item.valueCtl.hashCode],
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _onDeleteItem(list, addedSet, item, isFasilitas),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          // Chips row to add categories (placed after the list so new items show above)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCategories.map((cat) {
              final already = addedSet.contains(cat);
              return ChoiceChip(
                selected: already,
                onSelected: (sel) {
                  if (sel && !addedSet.contains(cat)) {
                    setState(() {
                      // if previously removed, unmark it so saving will include it again
                      _removedFasilitas.remove(cat);
                      _removedTenaga.remove(cat);
                      final it = _EditableMetric(label: cat, value: '0');
                      list.insert(0, it); // put new item on top
                      _ownedControllers.add(it.valueCtl);
                      addedSet.add(cat);
                    });
                  }
                },
                // use avatar to render a compact leading icon so spacing is consistent
                avatar: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 4),
                  child: Icon(
                    already ? Icons.check : Icons.add,
                    size: 16,
                    color: already ? Colors.black : Colors.grey[700],
                  ),
                ),
                label: Text(cat),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white,
                selectedColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Edit Data Kesehatan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perbarui informasi sarana kesehatan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            TabBar(
              isScrollable: false,
              labelColor: const Color(0xFF06B6D4),
              unselectedLabelColor: Colors.grey[600],
              tabs: const [Tab(text: 'Fasilitas'), Tab(text: 'Tenaga Medis')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildListTab(_fasilitasItems, widget.fasilitasCategories, true),
                  _buildListTab(_tenagaItems, widget.tenagaMedisCategories, false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Removed 'Batal' button to match Kependudukan UI
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
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
                                // use app-bar colors gradient to match Kesehatan app bar
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
