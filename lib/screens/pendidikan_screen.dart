import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/infrastruktur_repository_single.dart';
import '../services/notes_repository.dart';
import '../utils/responsive.dart';
import '../utils/pendidikan_constants.dart';

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
  String? _kodeWilayah;
  String? _desaId;
  final Map<String, dynamic> _data = {
    'negeri': <String, int>{},
    'swasta': <Map<String, dynamic>>[],
    'lb': <String, int>{},
    'keagamaan': <String, dynamic>{},
    'keterampilan': <String, int>{},
  };

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? kode;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) kode = (args['kodeWilayah'] as String?)?.trim();
      if (kode == null || kode.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        kode = prefs.getString('last_desa_kode');
      }
      kode ??= '6303052009';
      _kodeWilayah = kode;
      _desaId = await _repo.getDesaIdByKode(kode);
      await _loadFromRepo(kode);
      await _loadNotes(kode);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFromRepo(String kode) async {
    final year = DateTime.now().year;
    final pend = await _repo.getPendidikan(kode, year: year);

    final negeri = <String, int>{
      for (final e in pend.entries)
        if (e.key.toLowerCase().contains('negeri') && e.value > 0)
          e.key: e.value,
    };

    final swasta = PendidikanConstants.formal
        .map(
          (f) => {
            'label': f,
            'count': pend[f] ?? 0,
            'nearest_km': null,
            'akses': (pend[f] ?? 0) > 0 ? 'lokal' : 'mudah',
            'keterangan': (pend[f] ?? 0) > 0 ? 'unit lokal' : '',
          },
        )
        .toList();

    final lb = <String, int>{
      for (final s in PendidikanConstants.slb) s: pend[s] ?? 0,
    };

    final keagamaan = <String, dynamic>{
      for (final k in PendidikanConstants.keagamaanInt) k: pend[k] ?? 0,
      for (final k in PendidikanConstants.keagamaanBool)
        k: ((pend[k] ?? 0) > 0) ? 'Ada' : 'Tidak Ada',
    };

    final keterampilan = <String, int>{
      for (final k in PendidikanConstants.keterampilan) k: pend[k] ?? 0,
    };

    _data['negeri'] = negeri;
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
    } catch (_) {}
  }

  // ---------------- UI BUILD -----------------
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pendidikan')),
        body: Center(child: Text('Gagal memuat data pendidikan\n$_error')),
      );
    }
    final negeri = Map<String, int>.from(_data['negeri']);
    final swasta = List<Map<String, dynamic>>.from(_data['swasta']);
    final lb = Map<String, int>.from(_data['lb']);
    final keagamaan = Map<String, dynamic>.from(_data['keagamaan']);
    final keterampilan = Map<String, int>.from(_data['keterampilan']);

    final totalNegeri = negeri.values.fold<int>(0, (p, c) => p + c);
    final totalSwasta = swasta.fold<int>(0, (p, e) => p + (e['count'] as int));

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
                      Color(0xFF2563EB), // blue
                      Color(0xFF1D4ED8), // darker blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x402563EB),
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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                toolbarHeight: 56,
                title: const Text(
                  'Pendidikan',
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
                          Color(0xFF2563EB), // blue
                          Color(0xFF1D4ED8), // darker blue
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
                    12,
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
                        label: 'Lembaga Swasta',
                        value: '$totalSwasta',
                        icon: Icons.apartment_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _section(_buildNegeri(negeri)),
                    _section(_buildSwasta(swasta)),
                    _section(_buildLBKeagamaan(lb, keagamaan, keterampilan)),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
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
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF2563EB),
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
                text: 'LB & Keag',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------- Section builders -------
  Widget _buildNegeri(Map<String, int> negeri) {
    final entries = negeri.entries.toList();
    final total = entries.fold<int>(0, (p, c) => p + c.value);
    return _Card(
      icon: Icons.account_balance_rounded,
      title: 'Lembaga Pendidikan Negeri',
      subtitle: entries.isEmpty ? 'Belum ada' : 'Total: $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            _infoBanner(
              icon: Icons.info_rounded,
              title: 'Belum ada lembaga negeri',
              message: 'Tambahkan melalui tombol edit.',
              color: const Color(0xFF2563EB),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map(
                    (e) => _chip(
                      icon: Icons.check_circle_rounded,
                      label: e.key,
                      value: e.value.toString(),
                      color: const Color(0xFF10B981),
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
    // Tampilkan hanya entri yang memiliki data (count > 0)
    final displayed = swasta
        .where((e) => (e['count'] as int? ?? 0) > 0)
        .toList(growable: false);
    final total = displayed.fold<int>(0, (p, e) => p + (e['count'] as int));
    return _Card(
      icon: Icons.apartment_rounded,
      title: 'Lembaga Pendidikan Swasta',
      subtitle: 'Total lokal: $total',
      child: Column(
        children: [
          ...displayed.map(_swastaTile),
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
    final hasTBM = (keagamaan['TBM'] ?? 'Tidak Ada') == 'Ada';
    final hasPaket = (keagamaan['Paket A/B/C'] ?? 'Tidak Ada') == 'Ada';

    final lbEntries = lb.entries.where((e) => e.value > 0).toList();
    final keagEntries = <Widget>[
      if ((keagamaan['Pesantren'] ?? 0) > 0)
        _chip(
          icon: Icons.mosque_rounded,
          label: 'Pesantren',
          value: (keagamaan['Pesantren'] ?? 0).toString(),
          color: const Color(0xFF2563EB),
        ),
      if ((keagamaan['Madrasah'] ?? 0) > 0)
        _chip(
          icon: Icons.menu_book_rounded,
          label: 'Madrasah',
          value: (keagamaan['Madrasah'] ?? 0).toString(),
          color: const Color(0xFF2563EB),
        ),
      if (hasPaket)
        _chip(
          icon: Icons.fact_check_rounded,
          label: 'Paket A/B/C',
          value: 'Ada',
          color: const Color(0xFF10B981),
        ),
      if (hasTBM)
        _chip(
          icon: Icons.local_library_rounded,
          label: 'TBM',
          value: 'Ada',
          color: const Color(0xFF10B981),
        ),
    ];
    final keterampilanEntries = keterampilan.entries
        .where((e) => e.value > 0)
        .map(
          (e) => _chip(
            icon: Icons.build_rounded,
            label: e.key,
            value: e.value.toString(),
            color: const Color(0xFF7C3AED),
          ),
        )
        .toList();

    return _Card(
      icon: Icons.school_rounded,
      title: 'LB, Keagamaan & Keterampilan',
      subtitle: 'Ringkasan data tersedia saja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lbEntries.isNotEmpty) ...[
            Text(
              'SLB',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lbEntries
                  .map(
                    (e) => _chip(
                      icon: Icons.accessibility_new_rounded,
                      label: e.key,
                      value: e.value.toString(),
                      color: const Color(0xFF2563EB),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (keagEntries.isNotEmpty) ...[
            Text(
              'Keagamaan',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: keagEntries),
            const SizedBox(height: 16),
          ],
          if (keterampilanEntries.isNotEmpty) ...[
            Text(
              'Keterampilan',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: keterampilanEntries),
            const SizedBox(height: 16),
          ],
          _catatan('LB/Keagamaan/Keterampilan'),
        ],
      ),
    );
  }

  // ------- Reusable small widgets -------
  Widget _swastaTile(Map<String, dynamic> e) {
    final label = e['label'] as String;
    final count = e['count'] as int;
    final akses = e['akses'] as String? ?? 'mudah';
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
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.12),
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
                      ? 'Tersedia $count ${ket.isNotEmpty ? '( $ket )' : ''}'
                      : (ket.isNotEmpty
                            ? 'Tidak ada lokal — $ket'
                            : 'Tidak ada lokal'),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          if (count == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$akses',
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.rs(10),
            offset: Offset(0, context.rs(4)),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(14)),
        child: Row(
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
                  Text(
                    value,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: context.rf(22),
                      fontWeight: FontWeight.bold,
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
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.3)),
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
    final sectionKey = switch (bagian) {
      'Negeri' => 'negeri',
      'Swasta' => 'swasta',
      'LB/Keagamaan/Keterampilan' => 'lb_keagamaan_keterampilan',
      _ => 'unknown',
    };
    final entry = _notesBySection[sectionKey];
    final title = entry != null ? entry['title'] as String : 'Catatan';
    final paras = entry != null
        ? List<String>.from(entry['paras'] as List)
        : const ['Ringkasan belum tersedia.'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
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

  Widget _section(Widget child) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    ),
  );

  // ------------- Bottom Sheet Editor -------------
  Future<void> _openEditBottomSheet() async {
    if (_kodeWilayah == null || _desaId == null) return;
    final kode = _kodeWilayah!;
    final desaId = _desaId!;
    final year = DateTime.now().year;
    final pend = await _repo.getPendidikan(kode, year: year);

    final items = pend.entries
        .map(
          (e) => _MetricEditItemInt(
            originalLabel: e.key,
            labelCtl: TextEditingController(text: e.key),
            valueCtl: TextEditingController(text: e.value.toString()),
          ),
        )
        .toList();
    // Notes: map each tab to a section key, with controllers for title/body
    String _sectionKeyForTab(int tab) => switch (tab) {
      0 => 'negeri',
      1 => 'swasta',
      _ => 'lb_keagamaan_keterampilan',
    };
    final Map<int, TextEditingController> _noteTitleCtl = {
      0: TextEditingController(),
      1: TextEditingController(),
      2: TextEditingController(),
    };
    final Map<int, TextEditingController> _noteBodyCtl = {
      0: TextEditingController(),
      1: TextEditingController(),
      2: TextEditingController(),
    };
    // Prefill from loaded notes map
    for (final t in [0, 1, 2]) {
      final key = _sectionKeyForTab(t);
      final entry = _notesBySection[key];
      if (entry != null) {
        _noteTitleCtl[t]!.text = (entry['title'] as String?) ?? '';
        final paras =
            (entry['paras'] as List?)?.cast<String>() ?? const <String>[];
        _noteBodyCtl[t]!.text = paras.join('\n');
      }
    }

    List<String> negeriSuggestions() {
      final existing = pend.keys.map((e) => e.toLowerCase()).toSet();
      return PendidikanConstants.formal
          .map((e) => '$e Negeri')
          .where((e) => !existing.contains(e.toLowerCase()))
          .toList()
        ..sort();
    }

    List<String> swastaSuggestions() {
      final existing = pend.keys.map((e) => e.toLowerCase()).toSet();
      return PendidikanConstants.formal
          .where((e) => !existing.contains(e.toLowerCase()))
          .toList()
        ..sort();
    }

    List<String> lbKeagSuggestions() {
      final existing = pend.keys.map((e) => e.toLowerCase()).toSet();
      final base = <String>{
        ...PendidikanConstants.slb,
        ...PendidikanConstants.keagamaanInt,
        ...PendidikanConstants.keagamaanBool,
        'Paket A/B/C',
        'TBM',
      };
      return base.where((e) => !existing.contains(e.toLowerCase())).toList()
        ..sort();
    }

    bool isNegeri(String l) => l.toLowerCase().contains('negeri');
    bool isLbKeag(String l) =>
        PendidikanConstants.slb.contains(l) ||
        PendidikanConstants.keagamaanInt.contains(l) ||
        PendidikanConstants.keagamaanBool.contains(l) ||
        l == 'Paket A/B/C' ||
        l == 'TBM';

    final formKey = GlobalKey<FormState>();
    final scrollCtl = ScrollController();
    final Map<int, FocusNode> _noteTitleNode = {
      0: FocusNode(),
      1: FocusNode(),
      2: FocusNode(),
    };
    final Map<int, FocusNode> _noteBodyNode = {
      0: FocusNode(),
      1: FocusNode(),
      2: FocusNode(),
    };
    bool saving = false;
    InputDecoration deco(String label) => InputDecoration(
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 3,
        child: StatefulBuilder(
          builder: (ctx, setLocal) => SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
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
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Edit Data Pendidikan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perbarui informasi sarana pendidikan',
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
                    Tab(text: 'Negeri'),
                    Tab(text: 'Swasta'),
                    Tab(text: 'LB & Keagamaan'),
                  ],
                ),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: TabBarView(
                      children: [
                        _buildTabContent(ctx, setLocal, items, formKey, scrollCtl, deco, 0, negeriSuggestions, isNegeri, _sectionKeyForTab, _noteTitleCtl, _noteBodyCtl, _noteTitleNode, _noteBodyNode),
                        _buildTabContent(ctx, setLocal, items, formKey, scrollCtl, deco, 1, swastaSuggestions, (l) => !isNegeri(l) && !isLbKeag(l), _sectionKeyForTab, _noteTitleCtl, _noteBodyCtl, _noteTitleNode, _noteBodyNode),
                        _buildTabContent(ctx, setLocal, items, formKey, scrollCtl, deco, 2, lbKeagSuggestions, isLbKeag, _sectionKeyForTab, _noteTitleCtl, _noteBodyCtl, _noteTitleNode, _noteBodyNode),
                      ],
                    ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                            final labels = items
                                .where(
                                  (e) =>
                                      !e.removed &&
                                      e.labelCtl.text.trim().isNotEmpty,
                                )
                                .map((e) => e.labelCtl.text.trim())
                                .toList();
                            final dup = <String, int>{};
                            for (final l in labels) {
                              dup[l] = (dup[l] ?? 0) + 1;
                            }
                            final dups = dup.entries
                                .where((e) => e.value > 1)
                                .map((e) => e.key)
                                .toList();
                            if (dups.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Label duplikat: ${dups.join(', ')}',
                                  ),
                                ),
                              );
                              return;
                            }
                            setLocal(() => saving = true);
                            try {
                              for (final item in items) {
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
                                final v =
                                    int.tryParse(item.valueCtl.text.trim()) ??
                                    0;
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
                              // Persist notes after metrics
                              for (final t in [0, 1, 2]) {
                                final section = _sectionKeyForTab(t);
                                final title = _noteTitleCtl[t]!.text.trim();
                                final body = _noteBodyCtl[t]!.text;
                                final paras = body
                                    .split(RegExp(r'\r?\n'))
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                await _notesRepo.upsertPendidikanNote(
                                  kodeWilayah: kode,
                                  desaId: desaId,
                                  year: year,
                                  section: section,
                                  title: title.isEmpty ? 'Catatan' : title,
                                  paras: paras,
                                );
                              }
                              await _loadFromRepo(kode);
                              await _loadNotes(
                                kode,
                              ); // refresh catatan agar langsung muncul
                              if (mounted) setState(() {});
                              if (mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Data pendidikan tersimpan'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setLocal(() => saving = false);
                            }
                          },
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext ctx,
    StateSetter setLocal,
    List<_MetricEditItemInt> items,
    GlobalKey<FormState> formKey,
    ScrollController scrollCtl,
    InputDecoration Function(String) deco,
    int tab,
    List<String> Function() getSuggestions,
    bool Function(String) filterFn,
    String Function(int) sectionKeyForTab,
    Map<int, TextEditingController> noteTitleCtl,
    Map<int, TextEditingController> noteBodyCtl,
    Map<int, FocusNode> noteTitleNode,
    Map<int, FocusNode> noteBodyNode,
  ) {
    final filtered = items
        .where((i) => !i.removed)
        .where((i) {
          final l = i.labelCtl.text.trim();
          return filterFn(l);
        })
        .toList();
    final suggestions = getSuggestions();

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollCtl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Tambah padding bottom untuk button sticky
            children: [
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: item.labelCtl,
                              decoration: deco('Jenis'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: item.valueCtl,
                              decoration: deco('Jumlah'),
                              keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return int.tryParse(v) == null
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
                    onPressed: () => setLocal(() => item.removed = true),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(
                          s,
                          style: const TextStyle(fontSize: 11),
                        ),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: () => setLocal(() {
                          items.add(
                            _MetricEditItemInt(
                              originalLabel: s,
                              labelCtl: TextEditingController(
                                text: s,
                              ),
                              valueCtl: TextEditingController(
                                text: '0',
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Judul Catatan (${sectionKeyForTab(tab)})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: noteTitleCtl[tab],
              focusNode: noteTitleNode[tab],
              decoration: deco('Judul Catatan'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: noteBodyCtl[tab],
              focusNode: noteBodyNode[tab],
              decoration: deco(
                'Tulis catatan, pisahkan per baris',
              ),
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
            ),
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
          onPressed: () => setLocal(() {
            final defaultLabel = switch (tab) {
              0 => 'Negeri Baru',
              2 => 'Keagamaan/SLB Baru',
              _ => 'Jenis Pendidikan',
            };
            items.add(
              _MetricEditItemInt(
                originalLabel: '_new_${items.length}',
                labelCtl: TextEditingController(
                  text: defaultLabel,
                ),
                valueCtl: TextEditingController(),
              ),
            );
          }),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Jenis Pendidikan'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    ],
  );
  }
}

/*
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
    final total = entries.isEmpty ? 0 : _sum(negeri);

    return _Card(
      icon: Icons.account_balance_rounded,
      title: 'Lembaga Pendidikan Negeri',
      subtitle: entries.isEmpty
          ? 'Belum ada lembaga pendidikan negeri'
          : 'Total entri negeri: $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            _infoBanner(
              icon: Icons.info_rounded,
              title: 'Belum ada lembaga negeri',
              message:
                  'Tambahkan melalui tombol Edit bila terdapat PAUD/TK/SD/SMP/SMA/SMK/PT Negeri.',
              color: const Color(0xFF2563EB),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map(
                    (e) => _chip(
                      icon: Icons.check_circle_rounded,
                      label: e.key,
                      value: e.value.toString(),
                      color: const Color(0xFF10B981),
                    ),
                  )
                  .toList(),
            ),
          ],
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
                      ? 'Tersedia $count ${ket.isNotEmpty ? '( $ket )' : ''}'
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
  // (Removed legacy duplicate _openEditBottomSheet implementation.)
}

*/
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

// Helper item for dynamic pendidikan editing
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
