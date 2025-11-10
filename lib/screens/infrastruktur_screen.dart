import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/infrastruktur_repository_single.dart';
import '../utils/responsive.dart';

class InfrastrukturScreen extends StatefulWidget {
  const InfrastrukturScreen({super.key});

  @override
  State<InfrastrukturScreen> createState() => _InfrastrukturScreenState();
}

class _InfrastrukturScreenState extends State<InfrastrukturScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = InfrastrukturRepositorySingle();

  bool _loading = true;
  String? _error;
  String? _kodeWilayah; // track current kode for save
  String? _desaId; // desa id for desa_id-based upserts

  // Data state yang akan diisi dari repository (tanpa hardcoded)
  final Map<String, dynamic> _data = {
    'pendidikan': <String, int>{},
    'kesehatan': <String, int>{},
    'tenaga_medis': <String, int>{},
    'jalan': <String, int>{},
    'angkutan': <String, int>{},
    'akses_pemerintahan': <String, Map<String, int>>{},
    'komunikasi': <String, int>{},
    'sanitasi': <String, int>{},
    'kebencanaan': <String, int>{},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Load kode wilayah (dari route args jika ada, jika tidak dari SharedPreferences), lalu fetch data dari Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndLoad());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    try {
      // 1) Ambil argumen route jika ada
      final args = ModalRoute.of(context)?.settings.arguments;
      String? kode;
      if (args is Map) {
        kode = (args['kodeWilayah'] as String?)?.trim();
      }
      // 2) Jika tidak ada, fallback ke SharedPreferences (last_desa_kode)
      if (kode == null || kode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        kode = prefs.getString('last_desa_kode');
      }
      // 3) Fallback terakhir (optional): kode default jika masih null/empty
      kode ??= '6303052009';
      _kodeWilayah = kode;
      _desaId = await _repo.getDesaIdByKode(kode);
      await _loadFromRepo(kode);
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

    // Pendidikan
    final pendidikan = await _repo.getPendidikan(kode, year: year);

    // Kesehatan
    final fasilitas = await _repo.getKesehatanFasilitas(kode, year: year);
    final tenaga = await _repo.getTenagaMedis(kode, year: year);

    // Transportasi & Jalan
    final jalanKm = await _repo.getJalanKm(
      kode,
      year: year,
    ); // Map<String,double>
    // UI saat ini memakai satuan (km) pada label dan integer untuk nilai, maka konversi ke int dengan pembulatan
    final jalanInt = <String, int>{
      for (final e in jalanKm.entries)
        // Tambahkan " (km)" ke label agar konsisten dengan UI lama
        '${e.key} (km)': e.value.round(),
    };

    final angkutan = await _repo.getAngkutan(kode, year: year);

    // Akses Pemerintahan
    final aksesList = await _repo.getAksesPemerintahan(kode, year: year);
    // Bentuk ulang ke struktur UI lama: {'Ke Camat': {'jarak_km': 12, 'waktu_menit': 25}, ...}
    final aksesMap = <String, Map<String, int>>{};
    for (final r in aksesList) {
      final label = (r['label'] as String?) ?? (r['tujuan'] as String? ?? '-');
      final jarak = (r['jarak_km'] as num?)?.toDouble() ?? 0.0;
      final waktu = (r['waktu_menit'] as num?)?.toInt() ?? 0;
      aksesMap[label] = {'jarak_km': jarak.round(), 'waktu_menit': waktu};
    }

    // Komunikasi
    final komunikasi = await _repo.getKomunikasi(kode, year: year) ?? {};
    // Transform ke kunci UI lama
    final komunikasiUi = <String, int>{
      'Menara BTS': ((komunikasi['bts_count'] as num?)?.toInt() ?? 0),
      'Operator Seluler':
          ((komunikasi['operator_count'] as num?)?.toInt() ?? 0),
      'Sinyal 4G (%)': ((komunikasi['cakupan_4g_pct'] as num?)?.round() ?? 0),
      'Internet Desa': ((komunikasi['internet_desa'] == true) ? 1 : 0),
      'Komputer (unit)': ((komunikasi['komputer_unit'] as num?)?.toInt() ?? 0),
      'TV/Radio (pusat)':
          ((komunikasi['tv_radio_pusat'] as num?)?.toInt() ?? 0),
    };

    // Sanitasi & Kebencanaan
    final sanitasi = await _repo.getSanitasi(kode, year: year);
    final kebencanaan = await _repo.getKebencanaan(kode, year: year);

    // Update state data (tanpa setState di sini; pemanggil yang setState setelah selesai)
    _data['pendidikan'] = pendidikan;
    _data['kesehatan'] = fasilitas;
    _data['tenaga_medis'] = tenaga;
    _data['jalan'] = jalanInt;
    _data['angkutan'] = angkutan;
    _data['akses_pemerintahan'] = aksesMap;
    _data['komunikasi'] = komunikasiUi;
    _data['sanitasi'] = sanitasi;
    _data['kebencanaan'] = kebencanaan;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Infrastruktur Desa')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gagal memuat data infrastruktur.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    return Scaffold(
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
                      Color(0xFFF97316), // orange
                      Color(0xFFEC4899), // pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40F97316),
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
                title: const _AppBarTitle(
                  title: 'Infrastruktur Desa',
                  subtitle:
                      'Pendidikan • Kesehatan • Transportasi • Komunikasi • Sanitasi',
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
                          Color(0xFFF97316), // orange
                          Color(0xFFEC4899), // pink
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
                        label: 'Fasilitas Pendidikan',
                        value: _sum(_data['pendidikan']).toString(),
                        icon: Icons.school_rounded,
                        color: const Color(0xFFF97316),
                      ),
                      _buildSummaryCard(
                        label: 'Fasilitas Kesehatan',
                        value: _sum(_data['kesehatan']).toString(),
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFFF97316),
                      ),
                      _buildSummaryCard(
                        label: 'Moda Transportasi',
                        value: _sum(_data['angkutan']).toString(),
                        icon: Icons.directions_bus_filled_rounded,
                        color: const Color(0xFFF97316),
                      ),
                      _buildSummaryCard(
                        label: 'Sarana Sanitasi',
                        value: _sum(_data['sanitasi']).toString(),
                        icon: Icons.wash_rounded,
                        color: const Color(0xFFF97316),
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
                  _buildSection(_buildPendidikan()),
                  _buildSection(_buildKesehatan()),
                  _buildSection(_buildTransportasiJalan()),
                  _buildSection(_buildKomunikasiInformasi()),
                  _buildSection(_buildSanitasiAirBersih()),
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
            labelColor: const Color(0xFFF97316),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFF97316),
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
                icon: Icon(Icons.school_rounded, size: 20),
                text: 'Pendidikan',
              ),
              Tab(
                icon: Icon(Icons.local_hospital_rounded, size: 20),
                text: 'Kesehatan',
              ),
              Tab(
                icon: Icon(Icons.traffic_rounded, size: 20),
                text: 'Transportasi',
              ),
              Tab(
                icon: Icon(Icons.wifi_tethering_rounded, size: 20),
                text: 'Komunikasi',
              ),
              Tab(icon: Icon(Icons.wash_rounded, size: 20), text: 'Sanitasi'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditBottomSheet() async {
    if (_kodeWilayah == null || _desaId == null) return;
    final kode = _kodeWilayah!;
    final desaId = _desaId!;
    // Build local editable structures from current _data
    final pendidikan = Map<String, int>.from(_data['pendidikan']);
    final kesehatan = Map<String, int>.from(_data['kesehatan']);
    final tenaga = Map<String, int>.from(_data['tenaga_medis']);
    final jalan = Map<String, int>.from(_data['jalan']); // displayed as int km
    final angkutan = Map<String, int>.from(_data['angkutan']);
    final akses = Map<String, Map<String, int>>.from(
      _data['akses_pemerintahan'],
    );
    final komunikasiUi = Map<String, int>.from(_data['komunikasi']);
    final sanitasi = Map<String, int>.from(_data['sanitasi']);
    final kebencanaan = Map<String, int>.from(_data['kebencanaan']);

    // Controllers
    TextEditingController intCtl(int v) =>
        TextEditingController(text: v.toString());
    TextEditingController dblCtlNum(num v) =>
        TextEditingController(text: v.toString());

    // Convert maps to editable item lists
    final List<_MetricEditItemInt> pendItems = pendidikan.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();
    final List<_MetricEditItemInt> kesItems = kesehatan.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();
    final List<_MetricEditItemInt> tenagaItems = tenaga.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();
    final List<_MetricEditItemDouble> jalanItems = jalan.entries
        .map(
          (e) => _MetricEditItemDouble(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: dblCtlNum(e.value),
          ),
        )
        .toList();
    final List<_MetricEditItemInt> angkutanItems = angkutan.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();
    final aksesItems = akses.entries
        .map(
          (e) => _AksesEditItem(
            labelCtl: TextEditingController(text: e.key),
            jarakCtl: TextEditingController(
              text: (e.value['jarak_km'] ?? 0).toString(),
            ),
            waktuCtl: TextEditingController(
              text: (e.value['waktu_menit'] ?? 0).toString(),
            ),
          ),
        )
        .toList();

    // Komunikasi mapping shortcuts
    final btsCtl = intCtl(komunikasiUi['Menara BTS'] ?? 0);
    final operatorCtl = intCtl(komunikasiUi['Operator Seluler'] ?? 0);
    final cakupanCtl = TextEditingController(
      text: (komunikasiUi['Sinyal 4G (%)'] ?? 0).toString(),
    );
    final internetDesa = ValueNotifier<bool>(
      (komunikasiUi['Internet Desa'] ?? 0) == 1,
    );
    final komputerCtl = intCtl(komunikasiUi['Komputer (unit)'] ?? 0);
    final tvCtl = intCtl(komunikasiUi['TV/Radio (pusat)'] ?? 0);

    final List<_MetricEditItemInt> sanitasiItems = sanitasi.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();
    final List<_MetricEditItemInt> bencanaItems = kebencanaan.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: intCtl(e.value),
          ),
        )
        .toList();

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> doSave() async {
              if (!formKey.currentState!.validate()) return;
              setLocalState(() => saving = true);
              try {
                final year = DateTime.now().year;
                // Duplicate label validation across dynamic domains
                bool hasDuplicate = false;
                String duplicateMessage = '';
                Map<String, List<String>> domainLabels = {
                  'Pendidikan': pendItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Fasilitas Kesehatan': kesItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Tenaga Medis': tenagaItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Jalan': jalanItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Moda Angkutan': angkutanItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Sanitasi': sanitasiItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Kebencanaan': bencanaItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                  'Akses Pemerintahan': aksesItems
                      .where(
                        (e) => !e.removed && e.labelCtl.text.trim().isNotEmpty,
                      )
                      .map((e) => e.labelCtl.text.trim())
                      .toList(),
                };
                for (final entry in domainLabels.entries) {
                  final counts = <String, int>{};
                  for (final l in entry.value) {
                    counts[l] = (counts[l] ?? 0) + 1;
                  }
                  final dups = counts.entries
                      .where((e) => e.value > 1)
                      .map((e) => e.key)
                      .toList();
                  if (dups.isNotEmpty) {
                    hasDuplicate = true;
                    duplicateMessage += '${entry.key}: ${dups.join(', ')}\n';
                  }
                }
                if (hasDuplicate) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Label duplikat ditemukan:\n$duplicateMessage'.trim(),
                        ),
                      ),
                    );
                  }
                  setLocalState(() => saving = false);
                  return; // abort save
                }
                // Pendidikan
                for (final item in pendItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'pendidikan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'pendidikan',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                    unit: 'unit',
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'pendidikan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }
                // Kesehatan fasilitas
                for (final item in kesItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'kesehatan_fasilitas',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'kesehatan_fasilitas',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                    unit: 'unit',
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'kesehatan_fasilitas',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }
                // Tenaga medis
                for (final item in tenagaItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'tenaga_medis',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'tenaga_medis',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                    unit: 'orang',
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'tenaga_medis',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }
                // Jalan km (strip suffix ' (km)')
                for (final item in jalanItems) {
                  if (item.removed) {
                    final keyOld = item.originalLabel.endsWith(' (km)')
                        ? item.originalLabel.substring(
                            0,
                            item.originalLabel.length - 5,
                          )
                        : item.originalLabel;
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'jalan',
                      jenis: keyOld,
                      metricName: 'panjang_km',
                    );
                    continue;
                  }
                  final labelRaw = item.labelCtl.text.trim();
                  if (labelRaw.isEmpty) continue;
                  final keyNew = labelRaw.endsWith(' (km)')
                      ? labelRaw.substring(0, labelRaw.length - 5)
                      : labelRaw;
                  final v =
                      double.tryParse(
                        item.valueCtl.text.trim().replaceAll(',', '.'),
                      ) ??
                      0.0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'jalan',
                    jenis: keyNew,
                    metricName: 'panjang_km',
                    valueNum: v,
                    unit: 'km',
                  );
                  final oldKeyStripped = item.originalLabel.endsWith(' (km)')
                      ? item.originalLabel.substring(
                          0,
                          item.originalLabel.length - 5,
                        )
                      : item.originalLabel;
                  if (keyNew != oldKeyStripped) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'jalan',
                      jenis: oldKeyStripped,
                      metricName: 'panjang_km',
                    );
                  }
                }
                // Angkutan
                for (final item in angkutanItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'angkutan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'angkutan',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                    unit: 'unit',
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'angkutan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }
                // Akses pemerintahan
                for (final item in aksesItems) {
                  if (item.removed) continue;
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final jarak =
                      double.tryParse(
                        item.jarakCtl.text.trim().replaceAll(',', '.'),
                      ) ??
                      0.0;
                  final waktu = int.tryParse(item.waktuCtl.text.trim()) ?? 0;
                  await _repo.upsertAkses(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    tujuan: label,
                    label: label,
                    jarakKm: jarak,
                    waktuMenit: waktu,
                  );
                }
                // Komunikasi
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'bts_count',
                  valueInt: int.tryParse(btsCtl.text.trim()) ?? 0,
                );
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'operator_count',
                  valueInt: int.tryParse(operatorCtl.text.trim()) ?? 0,
                );
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'cakupan_4g_pct',
                  valueNum:
                      double.tryParse(
                        cakupanCtl.text.trim().replaceAll(',', '.'),
                      ) ??
                      0.0,
                  unit: '%',
                );
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'internet_desa',
                  valueBool: internetDesa.value,
                );
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'komputer_unit',
                  valueInt: int.tryParse(komputerCtl.text.trim()) ?? 0,
                );
                await _repo.upsertMetric(
                  kodeWilayah: kode,
                  desaId: desaId,
                  year: year,
                  domain: 'komunikasi',
                  jenis: '-',
                  metricName: 'tv_radio_pusat',
                  valueInt: int.tryParse(tvCtl.text.trim()) ?? 0,
                );
                // Sanitasi & Kebencanaan
                for (final item in sanitasiItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'sanitasi',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'sanitasi',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'sanitasi',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }
                for (final item in bencanaItems) {
                  if (item.removed) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'kebencanaan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                    continue;
                  }
                  final label = item.labelCtl.text.trim();
                  if (label.isEmpty) continue;
                  final v = int.tryParse(item.valueCtl.text.trim()) ?? 0;
                  await _repo.upsertMetric(
                    kodeWilayah: kode,
                    desaId: desaId,
                    year: year,
                    domain: 'kebencanaan',
                    jenis: label,
                    metricName: 'jumlah',
                    valueInt: v,
                  );
                  if (label != item.originalLabel) {
                    await _repo.deleteMetric(
                      kodeWilayah: kode,
                      year: year,
                      domain: 'kebencanaan',
                      jenis: item.originalLabel,
                      metricName: 'jumlah',
                    );
                  }
                }

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                setState(() => _loading = true);
                await _loadFromRepo(kode);
                if (!mounted) return;
                setState(() => _loading = false);
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
                                'Data infrastruktur berhasil disimpan',
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
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
              } finally {
                if (mounted) setLocalState(() => saving = false);
              }
            }

            InputDecoration deco(String label, {String? hint}) =>
                InputDecoration(
                  labelText: label,
                  hintText: hint,
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
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                );

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: DefaultTabController(
                  length: 5,
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
                                  colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Edit Data Infrastruktur',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Perbarui informasi infrastruktur desa',
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
                          Tab(text: 'Pendidikan'),
                          Tab(text: 'Kesehatan'),
                          Tab(text: 'Transportasi'),
                          Tab(text: 'Komunikasi'),
                          Tab(text: 'Sanitasi'),
                        ],
                      ),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: TabBarView(
                            children: [
                              // Pendidikan
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    ...pendItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Jenis',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => pendItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${pendItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Pendidikan'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Kesehatan (fasilitas + tenaga)
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fasilitas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...kesItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Fasilitas',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => kesItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${kesItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Fasilitas'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tenaga Medis',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...tenagaItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Jabatan',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => tenagaItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${tenagaItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Tenaga'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Transportasi & jalan & akses
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jalan (km)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...jalanItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Jenis Jalan',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Panjang (km)',
                                                        ),
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return double.tryParse(
                                                                    v.replaceAll(
                                                                      ',',
                                                                      '.',
                                                                    ),
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => jalanItems.add(
                                            _MetricEditItemDouble(
                                              originalLabel:
                                                  '_new_${jalanItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Jenis Jalan'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Moda Angkutan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...angkutanItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Moda',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => angkutanItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${angkutanItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Moda'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Akses Pemerintahan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...aksesItems.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: item.labelCtl,
                                                decoration: deco('Tujuan'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                controller: item.jarakCtl,
                                                decoration: deco('Jarak (km)'),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 110,
                                              child: TextFormField(
                                                controller: item.waktuCtl,
                                                decoration: deco(
                                                  'Waktu (menit)',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Hapus',
                                              onPressed: () => setLocalState(
                                                () => item.removed = true,
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => aksesItems.add(
                                            _AksesEditItem(
                                              labelCtl: TextEditingController(),
                                              jarakCtl: TextEditingController(),
                                              waktuCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Akses'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Komunikasi
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: btsCtl,
                                      decoration: deco('Menara BTS'),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: operatorCtl,
                                      decoration: deco('Operator Seluler'),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: cakupanCtl,
                                      decoration: deco('Cakupan 4G (%)'),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: internetDesa,
                                      builder: (ctx, val, _) => SwitchListTile(
                                        value: val,
                                        onChanged: (v) =>
                                            internetDesa.value = v,
                                        title: const Text('Internet Desa'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: komputerCtl,
                                      decoration: deco('Komputer (unit)'),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: tvCtl,
                                      decoration: deco('TV/Radio (pusat)'),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              // Sanitasi & Kebencanaan
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sanitasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...sanitasiItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Sarana',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => sanitasiItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${sanitasiItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Sanitasi'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Kebencanaan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...bencanaItems
                                        .where((item) => !item.removed)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            item.labelCtl,
                                                        decoration: deco(
                                                          'Kegiatan / Sarana',
                                                        ),
                                                        validator: (v) =>
                                                            (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty)
                                                            ? 'Wajib diisi'
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextFormField(
                                                        controller:
                                                            item.valueCtl,
                                                        decoration: deco(
                                                          'Jumlah',
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty)
                                                            return null;
                                                          return int.tryParse(
                                                                    v,
                                                                  ) ==
                                                                  null
                                                              ? 'Angka tidak valid'
                                                              : null;
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  onPressed: () =>
                                                      setLocalState(
                                                        () =>
                                                            item.removed = true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => setLocalState(
                                          () => bencanaItems.add(
                                            _MetricEditItemInt(
                                              originalLabel:
                                                  '_new_${bencanaItems.length}',
                                              labelCtl: TextEditingController(),
                                              valueCtl: TextEditingController(),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Tambah Kebencanaan'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: saving ? null : doSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          color: Colors.white,
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
              ),
            );
          },
        );
      },
    );
  }

  // ---- Helpers UI ----
  Widget _buildSection(Widget child) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    ),
  );

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

  // ---- Sections ----
  Widget _buildPendidikan() {
    final data = Map<String, int>.from(_data['pendidikan']);
    final total = _sum(data);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      icon: Icons.school_rounded,
      title: 'Infrastruktur Pendidikan',
      subtitle:
          'Ketersediaan lembaga pendidikan formal & nonformal — Total: $total unit',
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data pendidikan periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...entries.map(
                  (e) => _modernHorizontalBar(
                    label: e.key,
                    value: e.value,
                    percentage: e.value / (total == 0 ? 1 : total) * 100,
                    color: _categoryColor(e.key),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildKesehatan() {
    final fasilitas = Map<String, int>.from(_data['kesehatan']);
    final tenaga = Map<String, int>.from(_data['tenaga_medis']);
    final totalFasilitas = _sum(fasilitas);

    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF0EA5E9),
      const Color(0xFF22C55E),
      const Color(0xFFEAB308),
    ];

    final entries = fasilitas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      icon: Icons.local_hospital_rounded,
      title: 'Infrastruktur Kesehatan',
      subtitle:
          'Fasilitas pelayanan kesehatan & tenaga medis — Total fasilitas: $totalFasilitas',
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data kesehatan periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          final pct = totalFasilitas == 0
                              ? 0
                              : e.value / totalFasilitas * 100;
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                Text(
                  'Tenaga Medis',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: tenaga.entries
                      .map(
                        (e) => Expanded(
                          child: _infoStat(
                            icon: e.key == 'Dokter'
                                ? Icons.medical_information_rounded
                                : e.key == 'Bidan'
                                ? Icons.pregnant_woman_rounded
                                : Icons.volunteer_activism_rounded,
                            label: e.key,
                            value: e.value.toString(),
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildTransportasiJalan() {
    final jalan = Map<String, int>.from(_data['jalan']);
    final angkutan = Map<String, int>.from(_data['angkutan']);
    final akses = Map<String, dynamic>.from(_data['akses_pemerintahan']);

    final maxJalan = jalan.values.fold<int>(0, (p, c) => c > p ? c : p);

    return _Card(
      icon: Icons.directions_car_filled_rounded,
      title: 'Transportasi & Jalan',
      subtitle: 'Akses dan mobilitas, jenis jalan & angkutan umum',
      child: jalan.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data transportasi periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxJalan * 1.3).toDouble(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (g) => const Color(0xFF2563EB),
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipItem: (g, gi, rod, ri) {
                            final label = jalan.keys.elementAt(g.x.toInt());
                            return BarTooltipItem(
                              '$label\n${rod.toY.toStringAsFixed(0)}',
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
                              if (v.toInt() >= 0 && v.toInt() < jalan.length) {
                                final label = jalan.keys.elementAt(v.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
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
                            interval: 5,
                            getTitlesWidget: (v, m) => Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
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
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      barGroups: List.generate(jalan.length, (index) {
                        final value = jalan.values.elementAt(index).toDouble();
                        final color = _transportColor(index);
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
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
                ),
                const SizedBox(height: 16),
                Text(
                  'Angkutan Umum',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: angkutan.entries
                      .map(
                        (e) => Expanded(
                          child: _infoStat(
                            icon: Icons.directions_bus_rounded,
                            label: e.key,
                            value: e.value.toString(),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Akses ke Kantor Pemerintahan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: akses.entries.map((e) {
                    final map = Map<String, int>.from(e.value);
                    return _chip(
                      icon: Icons.place_rounded,
                      label: e.key,
                      value:
                          '${map['jarak_km']} km • ${map['waktu_menit']} menit',
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Angkutan Umum',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: angkutan.entries
                      .map(
                        (e) => Expanded(
                          child: _infoStat(
                            icon: Icons.directions_bus_rounded,
                            label: e.key,
                            value: e.value.toString(),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Akses ke Kantor Pemerintahan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: akses.entries.map((e) {
                    final map = Map<String, int>.from(e.value);
                    return _chip(
                      icon: Icons.place_rounded,
                      label: e.key,
                      value:
                          '${map['jarak_km']} km • ${map['waktu_menit']} menit',
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildKomunikasiInformasi() {
    final data = Map<String, int>.from(_data['komunikasi']);

    return _Card(
      icon: Icons.wifi_tethering_rounded,
      title: 'Komunikasi & Informasi',
      subtitle: 'Sarana teknologi informasi & cakupan layanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _infoStat(
                  icon: Icons.network_cell_rounded,
                  label: 'Menara BTS',
                  value: data['Menara BTS'].toString(),
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoStat(
                  icon: Icons.sim_card_rounded,
                  label: 'Operator',
                  value: data['Operator Seluler'].toString(),
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoStat(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: 'Cakupan 4G',
                  value: '${data['Sinyal 4G (%)']}%',
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoStat(
                  icon: Icons.public_rounded,
                  label: 'Internet Desa',
                  value: data['Internet Desa'].toString(),
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoStat(
                  icon: Icons.computer_rounded,
                  label: 'Komputer',
                  value: data['Komputer (unit)'].toString(),
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoStat(
                  icon: Icons.tv_rounded,
                  label: 'TV/Radio',
                  value: data['TV/Radio (pusat)'].toString(),
                  color: const Color(0xFF9333EA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSanitasiAirBersih() {
    final sanitasi = Map<String, int>.from(_data['sanitasi']);
    final bencana = Map<String, int>.from(_data['kebencanaan']);
    final total = _sum(sanitasi);

    final entries = sanitasi.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      icon: Icons.wash_rounded,
      title: 'Sanitasi & Air Bersih',
      subtitle: 'Sarana prasarana sanitasi, air bersih & kesiapsiagaan',
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada data sanitasi periode ini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...entries.map(
                  (e) => _modernHorizontalBar(
                    label: e.key,
                    value: e.value,
                    percentage: e.value / (total == 0 ? 1 : total) * 100,
                    color: _sanitasiColor(e.key),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Penanggulangan Bencana & Pelestarian Alam',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bencana.entries
                      .map(
                        (e) => _chip(
                          icon: Icons.shield_rounded,
                          label: e.key,
                          value: e.value.toString(),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }

  // ---- UI building blocks ----
  Widget _modernHorizontalBar({
    required String label,
    required int value,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
                  end: (percentage / 100).clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) =>
                    FractionallySizedBox(widthFactor: value, child: child),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
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

  Widget _legendItem({
    required Color color,
    required String label,
    required int value,
  }) {
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

  Widget _chip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  // ---- Colors & Utils ----
  int _sum(Map<String, int> map) => map.values.fold(0, (p, c) => p + c);

  Color _categoryColor(String key) {
    switch (key) {
      case 'PAUD':
      case 'TK':
        return const Color(0xFFF59E0B);
      case 'SD':
      case 'SMP':
        return const Color(0xFF10B981);
      case 'SMA':
      case 'SMK':
        return const Color(0xFF2563EB);
      case 'Akademi/PT':
      case 'Madrasah':
      case 'Pesantren':
        return const Color(0xFF7C3AED);
      case 'TBM':
      case 'Lembaga Keterampilan':
        return const Color(0xFF06B6D4);
      default:
        return Colors.grey;
    }
  }

  Color _sanitasiColor(String key) {
    switch (key) {
      case 'MCK Umum':
        return const Color(0xFF06B6D4);
      case 'IPAL Komunal':
        return const Color(0xFF2563EB);
      case 'TPS/Bank Sampah':
        return const Color(0xFF10B981);
      case 'Sarana Air Bersih':
        return const Color(0xFFF97316);
      case 'Hidran Umum':
        return const Color(0xFF9333EA);
      case 'Tandon/Air Baku':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  Color _transportColor(int i) {
    final colors = [
      const Color(0xFF93C5FD),
      const Color(0xFF3B82F6),
      const Color(0xFF0EA5E9),
    ];
    return colors[i % colors.length];
  }
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
                  color: const Color(0xFFF97316).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFF97316), size: 24),
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

// Top-level compact two-line app bar title used by Infrastruktur screen
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

// Helper model for akses pemerintahan editing rows
class _AksesEditItem {
  _AksesEditItem({
    required this.labelCtl,
    required this.jarakCtl,
    required this.waktuCtl,
  });
  final TextEditingController labelCtl;
  final TextEditingController jarakCtl;
  final TextEditingController waktuCtl;
  bool removed = false;
}

// Generic metric edit item (integer based)
class _MetricEditItemInt {
  _MetricEditItemInt({
    required this.originalLabel,
    required this.labelCtl,
    required this.valueCtl,
  });
  final String originalLabel;
  final TextEditingController labelCtl;
  final TextEditingController valueCtl;
  bool removed = false;
}

// Generic metric edit item (double/decimal based)
class _MetricEditItemDouble {
  _MetricEditItemDouble({
    required this.originalLabel,
    required this.labelCtl,
    required this.valueCtl,
  });
  final String originalLabel;
  final TextEditingController labelCtl;
  final TextEditingController valueCtl;
  bool removed = false;
}
