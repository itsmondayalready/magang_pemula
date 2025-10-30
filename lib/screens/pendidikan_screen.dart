import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/responsive.dart';

class PendidikanScreen extends StatefulWidget {
  const PendidikanScreen({super.key});

  @override
  State<PendidikanScreen> createState() => _PendidikanScreenState();
}

class _PendidikanScreenState extends State<PendidikanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Data sesuai permintaan
  final Map<String, dynamic> _data = {
    // 1) Lembaga Pendidikan Negeri — semua 0
    'negeri': {
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
    },

    // 2) Lembaga Pendidikan Swasta di wilayah & sekitar
    // value: {count: int, nearest_km: double?, akses: 'mudah'|'sedang'|'sulit', keterangan: 'lokal'|'terdekat'}
    'swasta': [
      {
        'label': 'PAUD Swasta',
        'count': 1,
        'nearest_km': null,
        'akses': 'lokal',
        'keterangan': 'unit lokal',
      },
      {
        'label': 'TK Swasta',
        'count': 0,
        'nearest_km': 1.4,
        'akses': 'mudah',
        'keterangan': 'terdekat 1.4 km – mudah',
      },
      {
        'label': 'SD Swasta',
        'count': 0,
        'nearest_km': 0.2,
        'akses': 'mudah',
        'keterangan': 'terdekat 0.2 km – mudah',
      },
      {
        'label': 'SMP Swasta',
        'count': 0,
        'nearest_km': 1.5,
        'akses': 'mudah',
        'keterangan': 'terdekat 1.5 km – mudah',
      },
      {
        'label': 'SMA Swasta',
        'count': 0,
        'nearest_km': 3.2,
        'akses': 'mudah',
        'keterangan': 'terdekat 3.2 km – mudah',
      },
      {
        'label': 'SMK Swasta',
        'count': 0,
        'nearest_km': 5.8,
        'akses': 'mudah',
        'keterangan': 'terdekat 5.8 km – mudah',
      },
      {
        'label': 'Perguruan Tinggi Swasta',
        'count': 0,
        'nearest_km': 4.9,
        'akses': 'mudah',
        'keterangan': 'terdekat 4.9 km – mudah',
      },
    ],

    // 3) Pendidikan Luar Biasa (LB/SLB) & Keagamaan & Keterampilan
    'lb': {'SDLB': 0, 'SMPLB': 0, 'SMALB': 0},
    'keagamaan': {
      'Pondok Pesantren': 0,
      'Madrasah Diniyah Swasta': 1,
      'Paket A/B/C': 'Ada',
      'Taman Bacaan Masyarakat (TBM)': 'Ada',
    },
    'keterampilan': {'Bahasa': 0, 'Komputer': 0, 'Menjahit': 0, 'Montir': 0},
  };

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
    final negeri = Map<String, int>.from(_data['negeri']);
    final swasta = List<Map<String, dynamic>>.from(_data['swasta']);
    final lb = Map<String, int>.from(_data['lb']);
    final keagamaan = Map<String, dynamic>.from(_data['keagamaan']);
    final keterampilan = Map<String, int>.from(_data['keterampilan']);

    final totalNegeri = _sum(negeri);
    final totalSwastaLokal = swasta.fold<int>(
      0,
      (p, e) => p + (e['count'] as int),
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
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
    final akses = e['akses'] as String; // 'lokal' or 'mudah'
    final ket = e['keterangan'] as String;

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
                      : 'Tidak ada lokal — $ket',
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
    // Isi catatan diambil dari ringkasan pendidikan.pdf yang kamu berikan
    late final String title;
    late final List<String> paras;

    switch (bagian) {
      case 'Negeri':
        title = 'Catatan – Lembaga Pendidikan Formal (Negeri dan Swasta)';
        paras = [
          'Di Desa Melayu Ilir tidak terdapat satu pun lembaga pendidikan negeri, baik PAUD, TK, SD, SMP, SMA/SMK, maupun Perguruan Tinggi.',
          'Hanya terdapat satu PAUD swasta yang beroperasi di dalam desa. Sekolah lainnya berada di luar wilayah dengan jarak terdekat antara 0,2 km hingga 5,8 km, seluruhnya dikategorikan mudah dijangkau.',
          'Kondisi ini menandakan keterbatasan sarana pendidikan lokal dan ketergantungan warga pada fasilitas di desa tetangga.',
        ];
        break;
      case 'Swasta':
        title = 'Catatan – Akses Pendidikan dan Ketersediaan Fasilitas';
        paras = [
          'Walau sarana pendidikan di dalam desa terbatas, akses menuju sekolah di luar wilayah cukup baik. Jalan penghubung relatif mudah dilalui dan transportasi memungkinkan siswa bersekolah di wilayah sekitar.',
          'Akses tercepat adalah menuju SD swasta terdekat (0,2 km) dan SMP terdekat (1,5 km), sedangkan SMK terdekat berjarak sekitar 5,8 km. Hal ini menunjukkan infrastruktur transportasi dan mobilitas siswa sudah memadai, meskipun ketersediaan sekolah dalam desa masih nol.',
        ];
        break;
      case 'LB/Keagamaan/Keterampilan':
        title = 'Catatan – Pendidikan Khusus, Keagamaan, dan Keterampilan';
        paras = [
          'Tidak terdapat Sekolah Luar Biasa (SLB) di Desa Melayu Ilir, baik jenjang SDLB, SMPLB, maupun SMALB. Anak berkebutuhan khusus kemungkinan harus menempuh pendidikan ke luar wilayah. Diperlukan perhatian terhadap akses pendidikan disabilitas dan inklusi dalam perencanaan pendidikan desa.',
          'Desa memiliki 1 Madrasah Diniyah swasta dan kegiatan Paket A/B/C aktif bagi warga yang belum menyelesaikan pendidikan dasar-menengah, serta Taman Bacaan Masyarakat (TBM) untuk sarana literasi.',
          'Namun, belum ada lembaga pelatihan keterampilan (bahasa, komputer, menjahit, kecantikan, montir, elektronika). Pendidikan non-formal masih berfokus pada keagamaan dan literasi dasar, belum pada pelatihan vokasional atau peningkatan keterampilan kerja.',
        ];
        break;
      default:
        title = 'Catatan';
        paras = const ['Ringkasan belum tersedia.'];
        break;
    }

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
