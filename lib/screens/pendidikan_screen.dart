import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/infrastruktur_repository_single.dart';
import '../services/notes_repository.dart';
import '../utils/responsive.dart';

class PendidikanScreen extends StatefulWidget {
  const PendidikanScreen({super.key});

  @override
  State<PendidikanScreen> createState() => _PendidikanScreenState();
}

class _PendidikanScreenState extends State<PendidikanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = InfrastrukturRepositorySingle();
  final _notesRepo = NotesRepository();

  bool _loading = true;
  String? _error;

  // State data yang diisi dari repository (tanpa hardcode)
  final Map<String, dynamic> _data = {
    'negeri': <String, int>{},
    'swasta': <Map<String, dynamic>>[],
    'lb': <String, int>{},
    'keagamaan': <String, dynamic>{},
    'keterampilan': <String, int>{},
  };

  // Catatan dari DB, keyed by section code: 'negeri' | 'swasta' | 'lb_keagamaan_keterampilan'
  final Map<String, Map<String, dynamic>> _notesBySection = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndLoad());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    try {
      // Ambil kode wilayah dari route args atau SharedPreferences
      final args = ModalRoute.of(context)?.settings.arguments;
      String? kode;
      if (args is Map) {
        kode = (args['kodeWilayah'] as String?)?.trim();
      }
      if (kode == null || kode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        kode = prefs.getString('last_desa_kode');
      }
      kode ??= '6303052009';

      // Muat data utama terlebih dahulu; catatan tidak boleh menggagalkan layar
      await _loadFromRepo(kode);
      await _loadNotes(kode);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadFromRepo(String kode) async {
    final year = DateTime.now().year;

    // Ambil data pendidikan dari tabel serbaguna (jumlah per jenis)
    final pend = await _repo.getPendidikan(kode, year: year);

    // 1) Negeri: sesuai spesifikasi, semuanya 0 (tetap)
    _data['negeri'] = {
      'PAUD Negeri': 0,
      'TK Negeri': 0,
      'RA/BA Negeri': 0,
      'SD Negeri': 0,
      'SMP Negeri': 0,
      'MTs Negeri': 0,
      'SMA Negeri': 0,
      'MA Negeri': 0,
      'SMK Negeri': 0,
      'Perguruan Tinggi Negeri': 0,
    };

    // 2) Swasta: turunkan dari pend (jenis umum) -> label swasta
    List<Map<String, dynamic>> swasta = [
      {
        'label': 'PAUD Swasta',
        'count': (pend['PAUD'] ?? 0),
        'nearest_km': null, // isi jika ada di DB (metric lain)
        'akses': (pend['PAUD'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['PAUD'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'TK Swasta',
        'count': (pend['TK'] ?? 0),
        'nearest_km': null,
        'akses': (pend['TK'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['TK'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'SD Swasta',
        'count': (pend['SD'] ?? 0),
        'nearest_km': null,
        'akses': (pend['SD'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['SD'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'SMP Swasta',
        'count': (pend['SMP'] ?? 0),
        'nearest_km': null,
        'akses': (pend['SMP'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['SMP'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'SMA Swasta',
        'count': (pend['SMA'] ?? 0),
        'nearest_km': null,
        'akses': (pend['SMA'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['SMA'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'SMK Swasta',
        'count': (pend['SMK'] ?? 0),
        'nearest_km': null,
        'akses': (pend['SMK'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['SMK'] ?? 0) > 0 ? 'unit lokal' : '',
      },
      {
        'label': 'Perguruan Tinggi Swasta',
        'count': (pend['Akademi/PT'] ?? 0),
        'nearest_km': null,
        'akses': (pend['Akademi/PT'] ?? 0) > 0 ? 'lokal' : 'mudah',
        'keterangan': (pend['Akademi/PT'] ?? 0) > 0 ? 'unit lokal' : '',
      },
    ];

    // 3) Pendidikan Luar Biasa, Keagamaan & Keterampilan
    final lb = {'SDLB': 0, 'SMPLB': 0, 'SMALB': 0};
    final keagamaan = {
      'Pondok Pesantren': (pend['Pesantren'] ?? 0),
      'Madrasah Diniyah Swasta': (pend['Madrasah'] ?? 0),
      // Tampilkan 'Ada' jika DB memiliki entri > 0, selain itu 'Tidak Ada'
      'Paket A/B/C': (pend['Paket A/B/C'] ?? 0) > 0 ? 'Ada' : 'Tidak Ada',
      'Taman Bacaan Masyarakat (TBM)': (pend['TBM'] ?? 0) > 0
          ? 'Ada'
          : 'Tidak Ada',
    };
    final keterampilan = {
      'Bahasa': 0,
      'Komputer': 0,
      'Menjahit': 0,
      'Montir': 0,
    };

    // Mutakhirkan state data
    _data['swasta'] = swasta;
    _data['lb'] = lb;
    _data['keagamaan'] = keagamaan;
    _data['keterampilan'] = keterampilan;
  }

  Future<void> _loadNotes(String kode) async {
    try {
      final year = DateTime.now().year;
      final notes = await _notesRepo.getPendidikanNotes(kode, year: year);
      _notesBySection.clear();
      for (final n in notes) {
        final section = (n['section'] as String).toLowerCase();
        _notesBySection[section] = {
          'title': n['title'] as String,
          'paras': (n['paras'] as List<String>),
        };
      }
    } catch (_) {
      // Abaikan error catatan agar layar tetap tampil
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pendidikan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gagal memuat data pendidikan.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    final negeri = Map<String, int>.from(_data['negeri'] ?? <String, int>{});
    final swasta = List<Map<String, dynamic>>.from(
      _data['swasta'] ?? <Map<String, dynamic>>[],
    );
    final lb = Map<String, int>.from(_data['lb'] ?? <String, int>{});
    final keagamaan = Map<String, dynamic>.from(
      _data['keagamaan'] ?? <String, dynamic>{},
    );
    final keterampilan = Map<String, int>.from(
      _data['keterampilan'] ?? <String, int>{},
    );

    final totalNegeri = _sum(negeri);
    final totalSwastaLokal = swasta.fold<int>(
      0,
      (p, e) => p + ((e['count'] as int?) ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 56,
            title: const _AppBarTitle(
              title: 'Pendidikan',
              subtitle: 'Sarana & akses pendidikan desa',
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
                      Color(0xFF2563EB), // blue
                      Color(0xFF7C3AED), // purple
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
                  _summaryCard(
                    label: 'Lembaga Negeri',
                    value: '$totalNegeri',
                    icon: Icons.account_balance_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  _summaryCard(
                    label: 'Lembaga Swasta Lokal',
                    value: '$totalSwastaLokal',
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF2563EB),
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
              _section(_buildNegeri(negeri)),
              _section(_buildSwasta(swasta)),
              _section(_buildLBKeagamaan(lb, keagamaan, keterampilan)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF2563EB),
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
                icon: Icon(Icons.account_balance_rounded, size: 20),
                text: 'Negeri',
              ),
              Tab(
                icon: Icon(Icons.apartment_rounded, size: 20),
                text: 'Swasta',
              ),
              Tab(
                icon: Icon(Icons.school_rounded, size: 20),
                text: 'LB & Keagamaan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- sections ---
  Widget _buildNegeri(Map<String, int> negeri) {
    final entries = negeri.entries.toList();
    final total = _sum(negeri);

    return _Card(
      icon: Icons.account_balance_rounded,
      title: 'Lembaga Pendidikan Negeri',
      subtitle:
          'Tidak ada lembaga pendidikan negeri di seluruh jenjang — Total: $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            _infoBanner(
              icon: Icons.info_rounded,
              title: 'Belum ada lembaga negeri',
              message:
                  'Saat ini tidak terdapat PAUD/TK/SD/SMP/SMA/SMK/Perguruan Tinggi Negeri di desa. Arahkan siswa ke fasilitas terdekat di desa sekitar.',
              color: const Color(0xFF2563EB),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < entries.length) {
                            final label = entries[value.toInt()].key
                                .split(' ')
                                .first;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(entries.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: 0,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.25),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries
                .map(
                  (e) => _chip(
                    icon: Icons.close_rounded,
                    label: e.key,
                    value: '0',
                    color: Colors.red.shade400,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _catatan('Negeri'),
        ],
      ),
    );
  }

  Widget _buildSwasta(List<Map<String, dynamic>> swasta) {
    final lokalCount = swasta.fold<int>(0, (p, e) => p + (e['count'] as int));

    return _Card(
      icon: Icons.apartment_rounded,
      title: 'Lembaga Pendidikan Swasta di Wilayah & Sekitar',
      subtitle:
          'Tersedia $lokalCount unit lokal, lainnya terdekat dengan akses mudah',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...swasta.map(_swastaTile),
          const SizedBox(height: 16),
          _catatan('Swasta'),
        ],
      ),
    );
  }

  Widget _buildLBKeagamaan(
    Map<String, int> lb,
    Map<String, dynamic> keagamaan,
    Map<String, int> keterampilan,
  ) {
    final hasTBM = keagamaan['Taman Bacaan Masyarakat (TBM)'] == 'Ada';
    final hasPaket = keagamaan['Paket A/B/C'] == 'Ada';

    return _Card(
      icon: Icons.school_rounded,
      title: 'Pendidikan Luar Biasa, Keagamaan & Keterampilan',
      subtitle:
          'Ringkasan SLB, Pendidikan Keagamaan, Paket A/B/C, TBM dan Keterampilan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendidikan Luar Biasa (SLB)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lb.entries
                .map(
                  (e) => _chip(
                    icon: Icons.close_rounded,
                    label: e.key,
                    value: e.value.toString(),
                    color: Colors.red.shade400,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Pendidikan Keagamaan',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                icon: Icons.mosque_rounded,
                label: 'Pondok Pesantren',
                value: keagamaan['Pondok Pesantren'].toString(),
                color: Colors.red.shade400,
              ),
              _chip(
                icon: Icons.menu_book_rounded,
                label: 'Madrasah Diniyah Swasta',
                value: keagamaan['Madrasah Diniyah Swasta'].toString(),
                color: const Color(0xFF2563EB),
              ),
              _chip(
                icon: Icons.fact_check_rounded,
                label: 'Paket A/B/C',
                value: hasPaket ? 'Ada' : 'Tidak Ada',
                color: hasPaket ? const Color(0xFF10B981) : Colors.red.shade400,
              ),
              _chip(
                icon: Icons.local_library_rounded,
                label: 'TBM',
                value: hasTBM ? 'Ada' : 'Tidak Ada',
                color: hasTBM ? const Color(0xFF10B981) : Colors.red.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Lembaga Keterampilan',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keterampilan.entries
                .map(
                  (e) => _chip(
                    icon: Icons.build_rounded,
                    label: e.key,
                    value: e.value.toString(),
                    color: e.value > 0
                        ? const Color(0xFF7C3AED)
                        : Colors.red.shade400,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _catatan('LB/Keagamaan/Keterampilan'),
        ],
      ),
    );
  }

  // --- small elements ---
  Widget _swastaTile(Map<String, dynamic> e) {
    final label = e['label'] as String;
    final count = e['count'] as int;
    final nearestKm = e['nearest_km'] as double?;
    final akses = e['akses'] as String? ?? 'mudah'; // 'lokal' or 'mudah'
    final ket = (e['keterangan'] as String?) ?? '';

    final color = count > 0 ? const Color(0xFF7C3AED) : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              count > 0 ? Icons.check_circle_rounded : Icons.place_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count > 0
                      ? 'Tersedia $count ${ket.isNotEmpty ? '($ket)' : ''}'
                      : (ket.isNotEmpty
                            ? 'Tidak ada lokal — $ket'
                            : 'Tidak ada lokal'),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          if (nearestKm != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${nearestKm.toStringAsFixed(1)} km • $akses',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
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

  Widget _chip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _catatan(String bagian) {
    // Ambil catatan dari DB sesuai section; fallback jika belum tersedia
    // Map UI label -> section key di DB
    final sectionKey = switch (bagian) {
      'Negeri' => 'negeri',
      'Swasta' => 'swasta',
      'LB/Keagamaan/Keterampilan' => 'lb_keagamaan_keterampilan',
      _ => 'unknown',
    };

    final entry = _notesBySection[sectionKey];
    final String title = entry != null ? (entry['title'] as String) : 'Catatan';
    final List<String> paras = entry != null
        ? List<String>.from(entry['paras'] as List)
        : const ['Ringkasan belum tersedia.'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...paras.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(t, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- appbar title helper & banner ---
  Widget _infoBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey[800], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- containers ---
  Widget _section(Widget child) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    ),
  );

  int _sum(Map<String, int> map) => map.values.fold(0, (p, c) => p + c);
}

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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
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

// Top-level compact two-line app bar title used by Pendidikan screen
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
