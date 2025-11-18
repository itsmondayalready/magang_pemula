// ...existing code...
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/desa_repository.dart';
import '../services/kesehatan_repository.dart';
import '../services/pendidikan_repository.dart';
import '../utils/responsive.dart';

// Shared simple text field builder for Add/Edit Desa forms
Widget _buildSimpleTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  String? Function(String?)? validator,
  void Function(String)? onFieldSubmitted,
  bool readOnly = false,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    keyboardType: keyboardType,
    textInputAction: textInputAction ?? TextInputAction.next,
    validator: validator,
    onFieldSubmitted: onFieldSubmitted,
    readOnly: readOnly,
  );
}

// Main menu screen untuk aplikasi Desa — versi yang rapi
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({
    super.key,
    required this.desaName,
    required this.kodeWilayah,
    required this.totalPenduduk,
    required this.totalKK,
    required this.isAdmin,
  });

  final String desaName;
  final String kodeWilayah;
  final int totalPenduduk;
  final int totalKK;
  final bool isAdmin;

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  late String _desaName;
  late String _kodeWilayah;

  // Summary data (loaded from DB)
  double? _luasWilayahKm2;
  int? _totalRT;
  int? _totalRW;
  int? _latestPenduduk;
  int? _latestKK;
  int? _totalFasilitas;
  int? _totalTenagaMedis;
  int? _totalPendidikanNegeri;
  int? _totalPendidikanSwasta;
  bool _loadingSummary = true;
  final _repo = DesaRepository();
  final _kesehatanRepo = KesehatanRepository();

  @override
  void initState() {
    super.initState();
    _desaName = widget.desaName;
    _kodeWilayah = widget.kodeWilayah;
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    // load summary from DB
    if (mounted)
      setState(() {
        _loadingSummary = true;
      }); // show loader
    try {
      await Future(() async {
        // Detail desa + profile (luas, RT/RW)
        final detail = await _repo.fetchDesaDetailByKode(_kodeWilayah);
        if (detail != null) {
          final p = detail['desa_profile'] as Map<String, dynamic>?;
          _luasWilayahKm2 = (p?['luas_wilayah'] as num?)?.toDouble();
          _totalRT = p?['total_rt'] as int?;
          _totalRW = p?['total_rw'] as int?;
        }

        // Kependudukan terbaru (total penduduk & KK)
        final kep = await _repo.fetchLatestKependudukanByKode(_kodeWilayah);
        _latestPenduduk = kep?['total_penduduk'] as int?;
        _latestKK = kep?['total_kk'] as int?;

        // Kesehatan terbaru (fasilitas & tenaga medis)
        final kes = await _kesehatanRepo.fetchLatest(_kodeWilayah);
        _totalFasilitas = (kes?['total_fasilitas'] ?? 0) as int?;
        _totalTenagaMedis = (kes?['total_tenaga_medis'] ?? 0) as int?;

        // Pendidikan: load data dari database
        final pendidikanRepo = PendidikanRepository();
        final pendidikanCounts = await pendidikanRepo.getCounts(_kodeWilayah);
        
        // Hitung total negeri (SD, SMP, SMA, SMK)
        final sd = pendidikanCounts['SD'] ?? 0;
        final smp = pendidikanCounts['SMP'] ?? 0;
        final sma = pendidikanCounts['SMA'] ?? 0;
        final smk = pendidikanCounts['SMK'] ?? 0;
        _totalPendidikanNegeri = sd + smp + sma + smk;
        
        // Hitung total swasta (PAUD, TK)
        final paud = pendidikanCounts['PAUD'] ?? 0;
        final tk = pendidikanCounts['TK'] ?? 0;
        _totalPendidikanSwasta = paud + tk;
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // timeout: leave values as null so UI shows placeholders
    } catch (_) {
      // ignore errors, keep nulls
    } finally {
      if (mounted)
        setState(() {
          _loadingSummary = false;
        });
    }
  }

  Future<void> _changeWilayah() async {
    final selected = await showModalBottomSheet<_DesaData?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _DesaPickerSheet(),
    );
    if (selected != null) {
      // Jika sentinel __RELOAD__, ambil desa valid dari DB
      if (selected.nama == '__RELOAD__' || selected.kode == '__RELOAD__') {
        final repo = DesaRepository();
        final fallback = await repo.fetchDefaultDesa();
        if (fallback != null) {
          final newKode = (fallback['kode_wilayah'] ?? '') as String;
          final newNama = (fallback['nama'] ?? 'Desa') as String;
          setState(() {
            _desaName = newNama;
            _kodeWilayah = newKode;
          });
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_desa_kode', newKode);
            await prefs.setString('last_desa_name', newNama);
          } catch (_) {}
          await _loadSummary();
        }
        return;
      }
      setState(() {
        _desaName = selected.nama;
        _kodeWilayah = selected.kode;
      });
      // Persist selection for next app launch
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_desa_kode', selected.kode);
        await prefs.setString('last_desa_name', selected.nama);
      } catch (_) {}
      await _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main data categories (sesuai gambar yang dikirim)
    final dataCategories = <_Feature>[
      _Feature(
        title: 'Profil Desa',
        icon: Icons.account_balance_rounded,
        gradient: _gradPurplePink,
        route: '/profil-desa',
      ),
      _Feature(
        title: 'Kependudukan',
        icon: Icons.people_alt_rounded,
        gradient: _gradEmeraldGold,
        route: '/kependudukan',
      ),
      _Feature(
        title: 'Kesehatan',
        icon: Icons.local_hospital_rounded,
        gradient: _gradCyanBlue,
        route: '/kesehatan',
      ),
      _Feature(
        title: 'Infrastruktur',
        icon: Icons.maps_home_work_rounded,
        gradient: _gradOrangePink,
        route: '/infrastruktur',
      ),
      _Feature(
        title: 'Pendidikan',
        icon: Icons.school_rounded,
        gradient: _gradBluePurple,
        route: '/pendidikan',
      ),
      _Feature(
        title: 'Kebencanaan',
        icon: Icons.cloud_rounded,
        gradient: _gradRedOrange,
        route: '/kebencanaan',
      ),
      _Feature(
        title: 'Metadata',
        icon: Icons.storage_rounded,
        gradient: _gradGreenLime,
        route: '/metadata',
      ),
    ];

    // Static paddings for the fixed carousel
    const double topPad = 12;
    const double bottomPad = 20; // loosen spacing below carousel

    // Prepare carousel items (dynamic from DB with graceful fallback)
    final luasStr = _luasWilayahKm2 != null && _luasWilayahKm2! > 0
        ? '${_luasWilayahKm2!.toStringAsFixed(2)} km²'
        : '—';
    final rtRwStr = (_totalRT != null && _totalRW != null)
        ? '$_totalRT/$_totalRW'
        : '—';
    final pendudukStr = _latestPenduduk != null && _latestPenduduk! > 0
        ? _latestPenduduk!.toString()
        : '—';
    final kkStr = _latestKK != null && _latestKK! > 0
        ? _latestKK!.toString()
        : '—';
    final negeriStr = _totalPendidikanNegeri != null && _totalPendidikanNegeri! > 0
        ? _totalPendidikanNegeri!.toString()
        : '—';
    final swastaStr = _totalPendidikanSwasta != null && _totalPendidikanSwasta! > 0
        ? _totalPendidikanSwasta!.toString()
        : '—';
    final fasilitasStr = _totalFasilitas != null && _totalFasilitas! > 0
        ? _totalFasilitas!.toString()
        : '—';
    final tenagaStr = _totalTenagaMedis != null && _totalTenagaMedis! > 0
        ? _totalTenagaMedis!.toString()
        : '—';
    final summaryItems = <_SummaryItem>[
      _SummaryItem(
        title: 'Ringkasan Desa',
        gradient: _gradLogin,
        icon: Icons.landscape_rounded,
        chips: [
          _SummaryChip(
            icon: Icons.map_rounded,
            label: 'Luas Wilayah',
            value: luasStr,
          ),
          _SummaryChip(
            icon: Icons.location_city_rounded,
            label: 'RT/RW',
            value: rtRwStr,
          ),
        ],
      ),
      _SummaryItem(
        title: 'Kependudukan',
        gradient: _gradEmeraldGold,
        icon: Icons.people_rounded,
        chips: [
          _SummaryChip(
            icon: Icons.group_rounded,
            label: 'Total Penduduk',
            value: pendudukStr,
          ),
          _SummaryChip(icon: Icons.badge_rounded, label: 'KK', value: kkStr),
        ],
      ),
      // Data pendidikan dari database (bukan dummy lagi!)
      _SummaryItem(
        title: 'Pendidikan',
        gradient: _gradBluePurple,
        icon: Icons.school_rounded,
        chips: [
          _SummaryChip(
            icon: Icons.account_balance_rounded,
            label: 'Negeri',
            value: negeriStr,
          ),
          _SummaryChip(
            icon: Icons.child_care_rounded,
            label: 'Swasta',
            value: swastaStr,
          ),
        ],
      ),
      _SummaryItem(
        title: 'Kesehatan',
        gradient: _gradCyanBlue,
        icon: Icons.local_hospital_rounded,
        chips: [
          _SummaryChip(
            icon: Icons.local_hospital_rounded,
            label: 'Fasilitas',
            value: fasilitasStr,
          ),
          _SummaryChip(
            icon: Icons.volunteer_activism_rounded,
            label: 'Tenaga',
            value: tenagaStr,
          ),
        ],
      ),
    ];

    // Fixed (non-scrollable) header + carousel on top, scrollable menu below
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Static header (not vertically scrollable)
              Container(
                decoration: const BoxDecoration(
                  gradient: _gradLogin,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: _HeaderContent(
                  desaName: _desaName,
                  kodeWilayah: widget.kodeWilayah,
                  isAdmin: widget.isAdmin,
                  onChangeWilayah: _changeWilayah,
                  onLogout: () async {
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    await auth.signOut();
                  },
                  // Keep animation fully visible (no shrink)
                  shrinkOffset: 0,
                  minExtent: 140,
                  maxExtent: 180,
                ),
              ),
              // Static summary carousel (not vertically scrollable)
              // Put a solid white background behind it so the menu underneath is hidden.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    topPad,
                    context.horizontalPadding,
                    bottomPad,
                  ),
                  child: _SummaryCarousel(items: summaryItems),
                ),
              ),
              // Scrollable menu grid below
              Expanded(
                child: ScrollConfiguration(
                  behavior: _NoGlowBehavior(),
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          0,
                          context.horizontalPadding,
                          24,
                        ),
                        sliver: _FeatureGrid(features: dataCategories),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loadingSummary)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: ColoredBox(
                  // Darker overlay so the loading state stands out more
                  color: Colors.black.withValues(alpha: 0.18),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Removed sliver header delegate; header is now static above the scrollable grid.

class _HeaderContent extends StatefulWidget {
  const _HeaderContent({
    required this.desaName,
    required this.kodeWilayah,
    required this.isAdmin,
    required this.onChangeWilayah,
    required this.onLogout,
    required this.shrinkOffset,
    required this.minExtent,
    required this.maxExtent,
  });

  final String desaName;
  final String kodeWilayah;
  final bool isAdmin;
  final VoidCallback onChangeWilayah;
  final VoidCallback onLogout;
  final double shrinkOffset;
  final double minExtent;
  final double maxExtent;

  @override
  State<_HeaderContent> createState() => _HeaderContentState();
}

class _HeaderContentState extends State<_HeaderContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..value = 1.0;
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant _HeaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shrinkRange = widget.maxExtent - widget.minExtent;
    final factor = shrinkRange > 0
        ? (widget.shrinkOffset / shrinkRange).clamp(0.0, 1.0)
        : 0.0;
    final target = (1.0 - factor).clamp(0.0, 1.0);
    // set controller value after this frame to avoid 'setState during build' warnings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.value = target;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hanya teks 'Ubah Wilayah' yang bisa ditekan
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: widget.onChangeWilayah,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 2,
                              ),
                              child: Text(
                                'Ubah Wilayah',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Hanya teks nama desa yang bisa ditekan
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: widget.onChangeWilayah,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 2,
                              ),
                              child: Text(
                                widget.desaName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Tampilkan 'Kode' sebagai baris tersendiri
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 2,
                          ),
                          child: Text(
                            'Kode: ${widget.kodeWilayah}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Role badge di bawahnya, dengan padding kiri sama seperti teks di atas
                        FadeTransition(
                          opacity: _fade,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 2,
                            ),
                            child: _RoleBadge(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: widget.onLogout,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// The rest of the helper widgets/classes are included below (trimmed and improved)

// _StatChip removed — replaced by summary pills in _SummaryCarousel

// Search bar removed per request

// Disable default overscroll glow/indicator
class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // no glow/bounce indicator
  }
}

// Removed sliver carousel delegate; carousel is now static above the scrollable grid.

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});
  final List<_Feature> features;
  @override
  Widget build(BuildContext context) {
    // Responsive grid: 2 columns for mobile, 3 for tablet, 4 for desktop
    final crossAxisCount = context.gridCount(mobile: 2, tablet: 3, desktop: 4);
    final childAspectRatio = context.isTablet || context.isDesktop ? 1.2 : 1.15;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate((context, i) {
        final f = features[i];
        return _FeatureCard(feature: f);
      }, childCount: features.length),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final _Feature feature;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        // Navigate via named route, passing current desa context as arguments
        final parent = context.findAncestorStateOfType<_MainMenuPageState>();
        final args = {
          'kodeWilayah': parent?._kodeWilayah,
          'desaName': parent?._desaName,
        };
        final result = await Navigator.of(context).pushNamed(feature.route, arguments: args);
        
        // Reload summary data only if there were changes (conditional refresh)
        if (parent != null && parent.mounted && result == true) {
          parent._loadSummary();
        }
      },
      child: Ink(
        decoration: BoxDecoration(
          gradient: feature.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(feature.icon, color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                feature.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final String route;
  const _Feature({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.route,
  });
}

// _AdminBadge removed — replaced by _AdminBadgeCompact for compact/consistent use

// Compact variant of the admin badge used in the smaller header
// Replaced by _RoleBadge above

class _RoleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isGuest = auth.isGuest;
    final isAdmin = !(isGuest); // treat non-guest as admin for now
    final baseColor = isAdmin ? Colors.green : Colors.grey;
    final bgColor = isAdmin
        ? baseColor.withValues(alpha: 0.16)
        : baseColor.withValues(alpha: 0.08);
    final borderColor = baseColor.withValues(alpha: 0.24);
    final contentColor = isAdmin ? Colors.white : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.verified_user_rounded : Icons.person,
            color: contentColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isGuest ? 'Guest' : 'Admin',
            style: TextStyle(
              color: contentColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// _TopMenuCarousel removed — replaced by _SummaryCarousel above

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Halaman $title\n\nTODO: Implementasi CRUD & integrasi Firestore',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

// =========================
// Desa Picker (Bottom Sheet)
// =========================
class _DesaData {
  final String nama;
  final String kode;
  final String kecamatan;
  final int penduduk;

  const _DesaData({
    required this.nama,
    required this.kode,
    required this.kecamatan,
    required this.penduduk,
  });
}

class _DesaPickerSheet extends StatefulWidget {
  const _DesaPickerSheet();

  @override
  State<_DesaPickerSheet> createState() => _DesaPickerSheetState();
}

class _DesaPickerSheetState extends State<_DesaPickerSheet> {
  final _searchController = TextEditingController();
  final _repo = DesaRepository();
  List<_DesaData> _all = const [];
  List<_DesaData> _filteredList = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final rows = await _repo.fetchDesaList(search: search, limit: 200);
      final mapped = rows.map<_DesaData>((r) {
        return _DesaData(
          nama: (r['nama'] ?? '') as String,
          kode: (r['kode_wilayah'] ?? '') as String,
          kecamatan: (r['kecamatan'] ?? '') as String,
          penduduk: (r['total_penduduk'] as int?) ?? 0, // mungkin tidak ada
        );
      }).toList();
      _all = mapped;
      _filteredList = mapped;
    } catch (_) {
      // fallback ke list kosong
      _all = const [];
      _filteredList = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterDesa(String query) {
    if (query.isEmpty) {
      setState(() => _filteredList = _all);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredList = _all
            .where(
              (d) =>
                  d.nama.toLowerCase().contains(q) ||
                  d.kecamatan.toLowerCase().contains(q) ||
                  d.kode.contains(query),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = !auth.isGuest;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Wilayah Desa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredList.length} desa tersedia',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterDesa,
                decoration: InputDecoration(
                  hintText: 'Cari nama desa, kecamatan, atau kode...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _filterDesa('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Desa list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada desa ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final desa = _filteredList[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _gradLogin,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_city_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            desa.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kec. ${desa.kecamatan} • ${desa.kode}'),
                              if (desa.penduduk > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${desa.penduduk} penduduk',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, desa),
                        );
                      },
                    ),
            ),
          ],
        ), // End Column
        
        // FAB for admin actions
        if (isAdmin)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _openAdminActionsSheet,
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      );
      },
    );
  }

  Future<void> _openAdminActionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: const Text('Tambah Desa'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _showAddDesaForm();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit Desa'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _showEditFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Hapus Desa'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _showDeleteFlow();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddDesaForm() async {
    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _AddDesaFormSheet(),
    );
    
    if (result != null && mounted) {
      // Refresh list
      await _load(search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());

      // Close picker and return new desa first, then show notification
      final kode = result['kode'] ?? '';
      final nama = result['nama'] ?? '';
      Navigator.pop(context, _DesaData(nama: nama, kode: kode, kecamatan: '', penduduk: 0));

      // Show success after sheet is closed
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
                        'Desa berhasil ditambahkan!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showEditFlow() async {
    final chosen = await _pickDesa(title: 'Pilih Desa untuk Diedit');
    if (chosen == null) return;
    
    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditDesaFormSheet(
        kodeWilayah: chosen.kode,
        initialNama: chosen.nama,
        initialKecamatan: chosen.kecamatan,
      ),
    );
    
    if (result != null && mounted) {
      await _load(search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());

      // Close picker and return edited desa first
      final kode = result['kode'] ?? '';
      final nama = result['nama'] ?? '';
      Navigator.pop(context, _DesaData(nama: nama, kode: kode, kecamatan: '', penduduk: 0));

      // Then show success notification
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
                        'Desa berhasil diperbarui!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteFlow() async {
    final chosen = await _pickDesa(title: 'Pilih Desa untuk Dihapus');
    if (chosen == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Hapus Desa'),
        content: Text(
          'Yakin ingin menghapus desa "${chosen.nama}" (${chosen.kode})?\nSemua data terkait akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;

    try {
      await _repo.deleteDesaByKode(chosen.kode);
      await _load(search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());
      
      if (mounted) {
        // Determine return value for picker closure (if deleted was active, try to get fallback)
        final parent = context.findAncestorStateOfType<_MainMenuPageState>();
        final needSwitch = parent != null && parent._kodeWilayah == chosen.kode;

        _DesaData? returnData;
        if (needSwitch) {
          try {
            final fallback = await _repo.fetchDefaultDesa();
            if (fallback != null) {
              final newKode = (fallback['kode_wilayah'] ?? '') as String;
              final newNama = (fallback['nama'] ?? 'Desa') as String;
              returnData = _DesaData(nama: newNama, kode: newKode, kecamatan: '', penduduk: 0);
            }
          } catch (_) {}
        }

        // If no special switch needed, return sentinel to reload
        returnData ??= const _DesaData(nama: '__RELOAD__', kode: '__RELOAD__', kecamatan: '', penduduk: 0);

        // Close picker first
        Navigator.pop(context, returnData);

        // Then show success notification
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
                          'Desa berhasil dihapus!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        String userMsg;
        if (errorMsg.contains('violates foreign key constraint')) {
          userMsg = 'Gagal menghapus desa. Data desa masih terhubung ke tabel lain.';
        } else {
          userMsg = 'Gagal menghapus desa. Silakan coba lagi.';
        }
        // Close picker first so notification appears on the underlying page
        Navigator.pop(context);

        // Then show error notification
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
                      Icons.error_outline_rounded,
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
                          'Gagal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userMsg,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<_DesaData?> _pickDesa({required String title}) async {
    return showModalBottomSheet<_DesaData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SelectDesaSheet(title: title, items: _filteredList),
    );
  }
}

// =========================
// Gradients
// =========================
// Login theme gradient (blue -> cyan -> green)
const _gradLogin = LinearGradient(
  colors: [Color(0xFF1976D2), Color(0xFF00BCD4), Color(0xFF4CAF50)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _gradEmeraldGold = LinearGradient(
  colors: [Color(0xFF0B7A75), Color(0xFFB08900)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradOrangePink = LinearGradient(
  colors: [Color(0xFFF97316), Color(0xFFEC4899)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradBluePurple = LinearGradient(
  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradCyanBlue = LinearGradient(
  colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradRedOrange = LinearGradient(
  colors: [Color(0xFFDC2626), Color(0xFFF97316)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradGreenLime = LinearGradient(
  colors: [Color(0xFF16A34A), Color(0xFFA3E635)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradPurplePink = LinearGradient(
  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
// removed unused gradients after carousel refactor

// =========================
// Summary Carousel (replacing header stats + small menu)
// =========================

class _SummaryCarousel extends StatefulWidget {
  const _SummaryCarousel({required this.items});
  final List<_SummaryItem> items;

  @override
  State<_SummaryCarousel> createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<_SummaryCarousel> {
  late final PageController _pageController;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Will be properly initialized in didChangeDependencies
    final len = widget.items.length;
    final base = len == 0 ? 0 : len * 1000;
    if (len > 0) {
      _index = base % len;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controller with responsive viewport fraction
    if (!_isControllerInitialized) {
      final viewportFraction = context.isDesktop
          ? 0.4
          : context.isTablet
          ? 0.6
          : 0.97;

      final len = widget.items.length;
      final base = len == 0 ? 0 : len * 1000;
      _pageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: base,
      );
      _isControllerInitialized = true;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && widget.items.isNotEmpty) {
        final nextPage = _pageController.page!.toInt() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isControllerInitialized = false;

  @override
  void dispose() {
    _timer?.cancel();
    if (_isControllerInitialized) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive height untuk carousel (ditambah agar muat layout vertikal pills)
    final height = context.isDesktop
        ? 170.0
        : context.isTablet
        ? 150.0
        : 140.0;

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!_isControllerInitialized) {
      return SizedBox(height: height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            // no itemCount -> infinite builder; map index via modulo
            onPageChanged: (i) =>
                setState(() => _index = i % widget.items.length),
            itemBuilder: (context, i) {
              final idx = i % widget.items.length;
              return _SummaryCard(data: widget.items[idx]);
            },
          ),
        ),
        SizedBox(height: context.rs(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: context.rs(3)),
              height: context.rs(6),
              width: i == _index ? context.rs(18) : context.rs(6),
              decoration: BoxDecoration(
                color: i == _index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String title;
  final Gradient gradient;
  final IconData icon;
  final List<_SummaryChip> chips;
  const _SummaryItem({
    required this.title,
    required this.gradient,
    required this.icon,
    required this.chips,
  });
}

class _SummaryChip {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});
  final _SummaryItem data;

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final horizontalPadding = context.rs(6);
    // Split card padding into four parts for granular control
    final double cardPaddingTop = context.rs(10.5);
    final double cardPaddingRight = context.rs(20.5);
    final double cardPaddingBottom = context.rs(10.5);
    final double cardPaddingLeft = context.rs(15.0);
    final borderRadius = context.rs(16);
    final iconSize = context.rs(44);
    final titleFontSize = context.rf(16);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: data.gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.fromLTRB(
          cardPaddingLeft,
          cardPaddingTop,
          cardPaddingRight,
          cardPaddingBottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: titleFontSize,
                    ),
                  ),
                  SizedBox(height: context.rs(8)),
                  // Susun seluruh pill menjadi atas-bawah (vertikal)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < data.chips.length; i++) ...[
                        _SummaryPill(
                          icon: data.chips[i].icon,
                          label: data.chips[i].label,
                          value: data.chips[i].value,
                        ),
                        if (i < data.chips.length - 1)
                          SizedBox(height: context.rs(8)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.rs(8)),
            Container(
              height: iconSize,
              width: iconSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(context.rs(12)),
              ),
              child: Icon(data.icon, color: Colors.white, size: context.rs(24)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10),
        vertical: context.rs(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.rs(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: context.rs(16)),
          SizedBox(width: context.rs(6)),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.rf(13),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// Form Add Desa
// =========================
class _AddDesaFormSheet extends StatefulWidget {
  const _AddDesaFormSheet();

  @override
  State<_AddDesaFormSheet> createState() => _AddDesaFormSheetState();
}

class _AddDesaFormSheetState extends State<_AddDesaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kodeCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _kecamatanCtrl = TextEditingController();
  final _kabupatenCtrl = TextEditingController(text: 'Banjar');
  final _provinsiCtrl = TextEditingController(text: 'Kalimantan Selatan');
  bool _submitting = false;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _kecamatanCtrl.dispose();
    _kabupatenCtrl.dispose();
    _provinsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
    });
    try {
      final repo = DesaRepository();
      await repo.createDesa(
        kodeWilayah: _kodeCtrl.text.trim(),
        nama: _namaCtrl.text.trim(),
        kecamatan: _kecamatanCtrl.text.trim(),
        kabupaten: _kabupatenCtrl.text.trim(),
        provinsi: _provinsiCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'kode': _kodeCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
      });
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        String userMsg;
        if (errorMsg.contains('violates foreign key constraint')) {
          userMsg = 'Gagal menambah desa. Data masih terhubung ke tabel lain.';
        } else if (errorMsg.contains('UNIQUE constraint failed')) {
          userMsg = 'Kode wilayah sudah digunakan. Silakan gunakan kode lain.';
        } else {
          userMsg = 'Gagal menambah desa. Silakan coba lagi.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userMsg,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tambah Desa Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Isi data desa dengan lengkap', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // ...existing code...
                  
                  // Form fields
                  _buildSimpleTextField(
                    controller: _kodeCtrl,
                    label: 'Kode Wilayah',
                    hint: 'Contoh: 6303052009',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleTextField(
                    controller: _namaCtrl,
                    label: 'Nama Desa',
                    hint: 'Contoh: Sungai Kupang',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleTextField(
                    controller: _kecamatanCtrl,
                    label: 'Kecamatan',
                    hint: 'Contoh: Kuripan',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleTextField(
                    controller: _kabupatenCtrl,
                    label: 'Kabupaten/Kota',
                    hint: 'Banjar',
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleTextField(
                    controller: _provinsiCtrl,
                    label: 'Provinsi',
                    hint: 'Kalimantan Selatan',
                    readOnly: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 28),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : () => Navigator.pop(context, null),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Batal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Shared simple text field builder for Add/Edit Desa forms
Widget _buildSimpleTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  String? Function(String?)? validator,
  void Function(String)? onFieldSubmitted,
  bool readOnly = false,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    keyboardType: keyboardType,
    textInputAction: textInputAction ?? TextInputAction.next,
    validator: validator,
    onFieldSubmitted: onFieldSubmitted,
    readOnly: readOnly,
  );
}
}

// =========================
// Form Edit Desa
// =========================
class _EditDesaFormSheet extends StatefulWidget {
  const _EditDesaFormSheet({
    required this.kodeWilayah,
    this.initialNama,
    this.initialKecamatan,
  });
  final String kodeWilayah;
  final String? initialNama;
  final String? initialKecamatan;

  @override
  State<_EditDesaFormSheet> createState() => _EditDesaFormSheetState();
}

class _EditDesaFormSheetState extends State<_EditDesaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kecamatanCtrl = TextEditingController();
  final _kabupatenCtrl = TextEditingController();
  final _provinsiCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kecamatanCtrl.dispose();
    _kabupatenCtrl.dispose();
    _provinsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.initialNama != null) _namaCtrl.text = widget.initialNama!;
    if (widget.initialKecamatan != null) _kecamatanCtrl.text = widget.initialKecamatan!;

    try {
      final detail = await DesaRepository().fetchDesaDetailByKode(widget.kodeWilayah);
      if (detail != null && mounted) {
        _namaCtrl.text = (detail['nama'] ?? _namaCtrl.text) as String;
        _kecamatanCtrl.text = (detail['kecamatan'] ?? _kecamatanCtrl.text) as String;
        _kabupatenCtrl.text = (detail['kabupaten'] ?? '') as String;
        _provinsiCtrl.text = (detail['provinsi'] ?? '') as String;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
    });
    try {
      await DesaRepository().updateDesaByKode(
        kodeWilayah: widget.kodeWilayah,
        nama: _namaCtrl.text.trim(),
        kecamatan: _kecamatanCtrl.text.trim(),
        kabupaten: _kabupatenCtrl.text.trim(),
        provinsi: _provinsiCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'kode': widget.kodeWilayah,
        'nama': _namaCtrl.text.trim(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2563EB),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal: ${e.toString().replaceFirst('Exception: ', '')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Edit Desa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(
                                    'Kode: ${widget.kodeWilayah}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // ...existing code...
                        
                        // Form fields
                        _buildSimpleTextField(
                          controller: _namaCtrl,
                          label: 'Nama Desa',
                          hint: 'Contoh: Sungai Kupang',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleTextField(
                          controller: _kecamatanCtrl,
                          label: 'Kecamatan',
                          hint: 'Contoh: Kuripan',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleTextField(
                          controller: _kabupatenCtrl,
                          label: 'Kabupaten/Kota',
                          hint: 'Banjar',
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleTextField(
                          controller: _provinsiCtrl,
                          label: 'Provinsi',
                          hint: 'Kalimantan Selatan',
                          readOnly: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 28),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : () => Navigator.pop(context, null),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _submit,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ...existing code...
}

// =========================
// Select Desa Sheet
// =========================
class _SelectDesaSheet extends StatelessWidget {
  const _SelectDesaSheet({required this.title, required this.items});
  final String title;
  final List<_DesaData> items;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final desa = items[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: _gradLogin,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white),
                    ),
                    title: Text(desa.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Kec. ${desa.kecamatan} • ${desa.kode}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, desa),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
