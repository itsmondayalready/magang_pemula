// ...existing code...
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../services/desa_repository.dart';
import '../services/kesehatan_repository.dart';
import '../services/infrastruktur_repository_single.dart';
import '../services/supabase_service.dart';
import '../utils/pendidikan_constants.dart';
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
  // Nomor WhatsApp diambil dari Profil Desa (telepon_kantor)
  String? _teleponKantor;

  // Summary data (loaded from DB)
  double? _luasWilayahKm2;
  int? _totalRT;
  int? _totalRW;
  int? _latestPenduduk;
  bool _loadingSummary = false;
  int? _totalFasilitas;
  int? _totalTenagaMedis;
  Map<String, int> _pendidikanNegeriCounts = {};
  Map<String, int> _pendidikanSwastaCounts = {};
  int? _totalPendidikanNegeri;
  int? _totalPendidikanSwasta;
  int? _latestKK;
  @override
  void initState() {
    super.initState();
    // Initialize required late fields from widget props so build() won't fail.
    _desaName = widget.desaName;
    _kodeWilayah = widget.kodeWilayah;

    // Try to restore last selected desa from shared prefs if available,
    // else keep values passed via constructor. Then load summary.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedKode = prefs.getString('last_desa_kode');
        final savedNama = prefs.getString('last_desa_name');
        if (savedKode != null && savedNama != null) {
          if (mounted) {
            setState(() {
              _kodeWilayah = savedKode;
              _desaName = savedNama;
            });
          }
        }
      } catch (_) {}
      if (mounted) await _loadSummary();
    });
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _loadingSummary = true);

    try {
      await Future(() async {
        // 1. Ambil detail desa untuk luas wilayah, RT/RW, telepon kantor
        final desaRepo = DesaRepository();
        final desaDetail = await desaRepo.fetchDesaDetailByKode(_kodeWilayah);

        if (desaDetail != null) {
          // Data ada di desa_profile
          final profile = desaDetail['desa_profile'];
          if (profile is Map) {
            _luasWilayahKm2 = (profile['luas_wilayah'] as num?)?.toDouble();
            _totalRT = (profile['total_rt'] as num?)?.toInt();
            _totalRW = (profile['total_rw'] as num?)?.toInt();
            _teleponKantor = profile['telepon_kantor'] as String?;
          } else if (profile is List && profile.isNotEmpty) {
            final p = profile[0] as Map;
            _luasWilayahKm2 = (p['luas_wilayah'] as num?)?.toDouble();
            _totalRT = (p['total_rt'] as num?)?.toInt();
            _totalRW = (p['total_rw'] as num?)?.toInt();
            _teleponKantor = p['telepon_kantor'] as String?;
          }
        }

        // 2. Ambil data kependudukan terbaru
        final kependudukan = await desaRepo.fetchLatestKependudukanByKode(
          _kodeWilayah,
        );
        if (kependudukan != null) {
          _latestPenduduk = (kependudukan['total_penduduk'] as num?)?.toInt();
          _latestKK = (kependudukan['total_kk'] as num?)?.toInt();
        }

        // 3. Kesehatan terbaru (fasilitas & tenaga medis)
        final kesehatanRepo = KesehatanRepository();
        final kes = await kesehatanRepo.fetchLatest(_kodeWilayah);
        _totalFasilitas = (kes?['total_fasilitas'] ?? 0) as int?;
        _totalTenagaMedis = (kes?['total_tenaga_medis'] ?? 0) as int?;

        // 4. Pendidikan: load lengkap dari repository (kategori sesuai form edit)
        final infraRepo = InfrastrukturRepositorySingle();
        final pendidikanMap = await infraRepo.getPendidikan(
          _kodeWilayah,
          year: DateTime.now().year,
        );

        // Reset detailed maps
        _pendidikanNegeriCounts = <String, int>{};
        _pendidikanSwastaCounts = <String, int>{};

        // Initialize zeroed maps for all formal labels so UI can read them.
        _pendidikanNegeriCounts = {
          for (final l in PendidikanConstants.formal) l: 0,
        };
        _pendidikanSwastaCounts = {
          for (final l in PendidikanConstants.formal) l: 0,
        };

        for (final entry in pendidikanMap.entries) {
          final key = entry.key.toString();
          final value = (entry.value as num?)?.toInt() ?? 0;
          if (value == 0) continue; // skip zeros

          final lc = key.toLowerCase();
          bool matched = false;
          for (final base in PendidikanConstants.formal) {
            final lcBase = base.toLowerCase();
            if (lc.contains(lcBase)) {
              if (lc.contains('negeri')) {
                _pendidikanNegeriCounts[base] =
                    (_pendidikanNegeriCounts[base] ?? 0) + value;
              } else {
                _pendidikanSwastaCounts[base] =
                    (_pendidikanSwastaCounts[base] ?? 0) + value;
              }
              matched = true;
              break;
            }
          }
          if (!matched) {
            final direct = PendidikanConstants.formal.firstWhere(
              (f) => f.toLowerCase() == key.toLowerCase(),
              orElse: () => '',
            );
            if (direct.isNotEmpty) {
              _pendidikanSwastaCounts[direct] =
                  (_pendidikanSwastaCounts[direct] ?? 0) + value;
            }
          }
        }

        // Totals are sums across the per-category maps
        _totalPendidikanNegeri = _pendidikanNegeriCounts.values.fold<int>(
          0,
          (p, c) => p + c,
        );
        _totalPendidikanSwasta = _pendidikanSwastaCounts.values.fold<int>(
          0,
          (p, c) => p + c,
        );
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // timeout: leave values as null so UI shows placeholders
    } catch (_) {
      // ignore errors, keep nulls
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
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

  String? _normalizePhoneForWa(String? phone) {
    if (phone == null) return null;
    final raw = phone.trim();
    if (raw.isEmpty) return null;
    String digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('0')) {
      // Asumsi Indonesia: ganti leading 0 dengan 62
      digits = '62${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _openWhatsApp() async {
    // Buka langsung aplikasi WhatsApp via deep link; fallback ke wa.me
    final defaultMessage = 'Halo Admin Desa';
    final number = _normalizePhoneForWa(_teleponKantor);
    if (number == null || number.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nomor kantor belum diisi di Profil Desa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Buka Profil',
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).pushNamed(
              '/profil-desa',
              arguments: {'kodeWilayah': _kodeWilayah, 'desaName': _desaName},
            ),
          ),
        ),
      );
      return;
    }

    final appUri = Uri.parse(
      'whatsapp://send?phone=$number&text=${Uri.encodeComponent(defaultMessage)}',
    );
    final webUri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(defaultMessage)}',
    );
    try {
      bool launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka WhatsApp'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka WhatsApp'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
        title: 'Tematik',
        icon: Icons.category_rounded,
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

    if (widget.isAdmin) {
      dataCategories.add(
        _Feature(
          title: 'Log Masuk',
          icon: Icons.history_rounded,
          gradient: _gradBlueHistory,
          route: '/log-masuk',
        ),
      );
    }

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
    final negeriStr =
        _totalPendidikanNegeri != null && _totalPendidikanNegeri! > 0
        ? _totalPendidikanNegeri!.toString()
        : '—';
    final swastaStr =
        _totalPendidikanSwasta != null && _totalPendidikanSwasta! > 0
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
            // Nilai sudah mengandung km², jadi tidak perlu unit terpisah
            unit: null,
          ),
          _SummaryChip(
            icon: Icons.location_city_rounded,
            label: 'RT/RW',
            value: rtRwStr,
            unit: null,
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
            unit: 'Jiwa',
          ),
          _SummaryChip(
            icon: Icons.badge_rounded,
            label: 'KK',
            value: kkStr,
            unit: 'KK',
          ),
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
            unit: 'Sekolah',
          ),
          _SummaryChip(
            icon: Icons.child_care_rounded,
            label: 'Swasta',
            value: swastaStr,
            unit: 'Sekolah',
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
            unit: 'Unit',
          ),
          _SummaryChip(
            icon: Icons.volunteer_activism_rounded,
            label: 'Tenaga',
            value: tenagaStr,
            unit: 'Orang',
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
                  kodeWilayah: _kodeWilayah,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openWhatsApp,
        tooltip: 'Hubungi via WhatsApp',
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
        shape: const CircleBorder(),
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
              children: [
                // Logo Desa (runtime asset) - sized & padded to avoid cropping
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.asset(
                            'lib/assets/GKL16_Banjar - Koleksilogo.com.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: widget.onChangeWilayah,
                          child: const Text(
                            'Ubah Wilayah',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: widget.onChangeWilayah,
                          child: Text(
                            widget.desaName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kode: ${widget.kodeWilayah}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(opacity: _fade, child: _RoleBadge()),
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
        final result = await Navigator.of(
          context,
        ).pushNamed(feature.route, arguments: args);

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
    final isAdmin = auth.isAdmin;
    final bool isUser = !isAdmin && !isGuest;

    final baseColor = isAdmin
        ? Colors.green
        : isGuest
        ? Colors.orange
        : Colors.grey;
    final bgColor = baseColor.withValues(alpha: isAdmin ? 0.16 : 0.08);
    final borderColor = baseColor.withValues(alpha: 0.24);
    final contentColor = isAdmin ? Colors.white : baseColor;

    final String label;
    if (isAdmin) {
      label = 'Admin';
    } else if (isGuest) {
      label = 'Guest';
    } else if (isUser) {
      label = 'User';
    } else {
      label = 'Unknown';
    }

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
            label,
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
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
      await _load(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      // Close picker and return new desa first, then show notification
      final kode = result['kode'] ?? '';
      final nama = result['nama'] ?? '';
      Navigator.pop(
        context,
        _DesaData(nama: nama, kode: kode, kecamatan: '', penduduk: 0),
      );

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      await _load(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      // Close picker and return edited desa first
      final kode = result['kode'] ?? '';
      final nama = result['nama'] ?? '';
      Navigator.pop(
        context,
        _DesaData(nama: nama, kode: kode, kecamatan: '', penduduk: 0),
      );

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteFlow() async {
    final chosen = await _pickDesa(title: 'Pilih Desa untuk Dihapus');
    if (chosen == null) return;
    // Check whether this desa has references in key tables
    Map<String, int> presence = const {};
    try {
      presence = await _repo.countDesaReferencesPresence(chosen.kode);
    } catch (_) {
      // If presence check fails, fall back to asking a simple confirmation
      presence = const {};
    }

    final hasRefs = presence.values.any((v) => v > 0);

    // Unified confirmation: ask once, then delete (cascade automatically if needed)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Hapus Desa'),
        content: Text(
          'Yakin ingin menghapus desa "${chosen.nama}" (${chosen.kode})? Semua data terkait akan dihapus.',
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dctx, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(dctx, true),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Hapus'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show progress modal while performing delete (cascade if needed)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (pctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                hasRefs ? 'Menghapus data terkait...' : 'Menghapus desa...',
              ),
            ),
          ],
        ),
      ),
    );

    try {
      if (hasRefs) {
        await _repo.deleteDesaCascadeClientSide(chosen.kode);
      } else {
        await _repo.deleteDesaByKode(chosen.kode);
      }
      Navigator.pop(context); // close progress dialog

      await _load(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (mounted) {
        final parent = context.findAncestorStateOfType<_MainMenuPageState>();
        final needSwitch = parent != null && parent._kodeWilayah == chosen.kode;

        _DesaData? returnData;
        if (needSwitch) {
          try {
            final fallback = await _repo.fetchDefaultDesa();
            if (fallback != null) {
              final newKode = (fallback['kode_wilayah'] ?? '') as String;
              final newNama = (fallback['nama'] ?? 'Desa') as String;
              returnData = _DesaData(
                nama: newNama,
                kode: newKode,
                kecamatan: '',
                penduduk: 0,
              );
            }
          } catch (_) {}
        }

        returnData ??= const _DesaData(
          nama: '__RELOAD__',
          kode: '__RELOAD__',
          kecamatan: '',
          penduduk: 0,
        );

        Navigator.pop(context, returnData);

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // close progress dialog
      if (mounted) {
        Navigator.pop(context); // close picker
        String userMsg = 'Gagal menghapus desa. Silakan coba lagi.';
        if (e.toString().contains('violates foreign key constraint')) {
          userMsg = 'Gagal menghapus desa. Data masih terhubung ke tabel lain.';
        }
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(userMsg, style: const TextStyle(fontSize: 12)),
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
            duration: const Duration(seconds: 4),
          ),
        );
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
const _gradBlueHistory = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
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
      if (!_pageController.hasClients || widget.items.isEmpty) return;
      final currentPage =
          _pageController.page ?? _pageController.initialPage.toDouble();
      final nextPage = currentPage.toInt() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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
  final String? unit; // satuan opsional
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
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
                          unit: data.chips[i].unit,
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
    this.unit,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

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
            '$label: $value${(unit != null && value != '—') ? ' $unit' : ''}',
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
  // CSV-driven selections
  bool _csvLoaded = false;
  bool _loadingDesa = true;
  String? _desaSource; // 'supabase' or 'csv' for debugging
  List<String> _kecamatanOptions = [];
  final Map<String, List<Map<String, String>>> _desaByKecamatan = {};
  String? _selectedKecamatan;
  String? _selectedDesaKode;
  String? _selectedDesaName;
  String? _csvErrorMessage;
  // Provinsi/Kabupaten autocomplete options - no longer used (fields are read-only)
  // kept for potential future use
  // ignore: unused_field
  List<String> _provinsiOptions = [];
  // ignore: unused_field
  List<String> _kabupatenOptions = [];

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _kecamatanCtrl.dispose();
    _kabupatenCtrl.dispose();
    _provinsiCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefer fetching dropdown data from Supabase (server) and fall back
    // to bundled CSV if the network/read fails. This populates
    // `_desaByKecamatan` and `_kecamatanOptions` used by the Autocomplete
    // widgets already present in the form.
    _loadFromSupabase();
    // seed province/kabupaten options with defaults
    _provinsiOptions = [
      _provinsiCtrl.text,
    ].where((s) => s.trim().isNotEmpty).toSet().toList();
    _kabupatenOptions = [
      _kabupatenCtrl.text,
    ].where((s) => s.trim().isNotEmpty).toSet().toList();
  }

  Future<void> _loadFromSupabase() async {
    if (mounted) setState(() => _loadingDesa = true);
    try {
      final byKec = await SupabaseService.fetchAllDesaDropdown();
      // Debug: record source and counts
      final totalDesa = byKec.values.fold<int>(0, (p, v) => p + v.length);
      debugPrint(
        'Supabase: loaded desa_dropdown — kecamatan=${byKec.length}, desa=$totalDesa',
      );
      _desaSource = 'supabase';
      final ks = byKec.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (mounted) {
        setState(() {
          _desaByKecamatan.clear();
          _desaByKecamatan.addAll(byKec);
          _kecamatanOptions = ks;
          // mark that data has been loaded from the primary source
          _csvLoaded = true;
          _csvErrorMessage = null;
        });
      }
    } catch (e, st) {
      debugPrint('Supabase fetch failed: $e\n$st');
      // mark that supabase failed; do NOT automatically fall back to CSV.
      // Leave the form able to accept manual input and show a helpful
      // error message instead. This enforces using the database as the
      // primary source during runtime.
      _desaSource = 'supabase_error';
      if (mounted) {
        setState(() {
          _csvLoaded = false;
          _csvErrorMessage =
              'Gagal memuat daftar dari Supabase: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingDesa = false);
    }
  }

  // Function retained for development fallback and local testing. We
  // currently prefer Supabase as the primary source; the method is kept
  // for manual use but may be unused in production builds.
  // ignore: unused_element
  Future<void> _loadCsvData() async {
    try {
      String raw;
      String usedPath = '';
      // During development prefer the lib-screen copy (no rebundle needed).
      // Fallback to bundled asset if lib copy is missing.
      try {
        raw = await rootBundle.loadString(
          'lib/screens/daftar_desa/hasil_bersih.csv',
        );
        usedPath = 'lib/screens/daftar_desa/hasil_bersih.csv';
      } catch (_) {
        raw = await rootBundle.loadString(
          'assets/daftar_desa/hasil_bersih.csv',
        );
        usedPath = 'assets/daftar_desa/hasil_bersih.csv';
      }
      debugPrint('Loaded desa CSV from: $usedPath');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return;
      // Expect header: Kecamatan,Kode Wilayah,Desa
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        // split into 3 parts only
        final parts = line.split(',');
        if (parts.length < 3) continue;
        final kec = parts[0].trim();
        final kode = parts[1].trim();
        final desa = parts.sublist(2).join(',').trim();
        if (kec.isEmpty || kode.isEmpty || desa.isEmpty) continue;
        _desaByKecamatan.putIfAbsent(kec, () => []).add({
          'desa': desa,
          'kode': kode,
        });
      }
      final ks = _desaByKecamatan.keys.toList()..sort();
      debugPrint(
        'Parsed kecamatan count=${ks.length}; sample=${ks.take(30).toList()}',
      );
      setState(() {
        _kecamatanOptions = ks;
        _csvLoaded = true;
        _csvErrorMessage = null;
      });
    } catch (e) {
      // capture error for debugging and show fallback
      final err = e.toString();
      debugPrint('Failed to load CSV: $err');
      if (mounted)
        setState(() {
          _csvLoaded = false;
          _csvErrorMessage = err;
        });
    }
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
      final errorMsg = e.toString();
      // detect duplicate/desa-exists errors (various DB messages)
      final lower = errorMsg.toLowerCase();
      final isDuplicate =
          lower.contains('duplicate') ||
          lower.contains('already exists') ||
          lower.contains('unique constraint failed') ||
          lower.contains('duplicate key');

      if (isDuplicate) {
        // close the current Add Desa sheet, then show the snackbar using the
        // navigator overlay context so it appears above the underlying sheet
        // prefer root navigator overlay so snackbar is shown above modal sheets
        final messengerContext =
            Navigator.of(context, rootNavigator: true).overlay?.context ??
            Navigator.of(context).overlay?.context ??
            context;
        // capture navigator so we can pop multiple times safely
        final nav = Navigator.of(context);
        if (mounted) nav.pop();
        // wait a short moment so the sheet is dismissed
        await Future.delayed(const Duration(milliseconds: 120));
        // attempt to also close the underlying picker sheet (if present)
        try {
          if (nav.canPop()) {
            nav.pop();
          }
        } catch (_) {}
        // wait a bit more for overlay to settle, then show snackbar
        await Future.delayed(const Duration(milliseconds: 80));
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gagal: Desa sudah ada',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Desa yang ingin ditambahkan sudah terdaftar.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      } else {
        if (mounted) {
          String userMsg;
          if (errorMsg.contains('violates foreign key constraint')) {
            userMsg =
                'Gagal menambah desa. Data masih terhubung ke tabel lain.';
          } else if (errorMsg.contains('UNIQUE constraint failed')) {
            userMsg =
                'Kode wilayah sudah digunakan. Silakan gunakan kode lain.';
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
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
                        child: const Icon(
                          Icons.add_location_alt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Desa Baru',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Isi data desa dengan lengkap',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // (debug banner removed) — source banner was developer-only

                  // ...existing code...

                  // Form fields (order: Provinsi -> Kabupaten -> Kecamatan -> Desa -> Kode Wilayah)
                  // When `_loadingDesa` is true we show a centered loading indicator
                  // that covers the entire fields area (Provinsi/Kabupaten/Kecamatan/Desa).
                  if (_loadingDesa)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    )
                  else ...[
                    // Provinsi (read-only)
                    _buildSimpleTextField(
                      controller: _provinsiCtrl,
                      label: 'Provinsi',
                      hint: 'Provinsi tidak dapat diubah',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    // Kabupaten/Kota (read-only)
                    _buildSimpleTextField(
                      controller: _kabupatenCtrl,
                      label: 'Kabupaten/Kota',
                      hint: 'Kabupaten tidak dapat diubah',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    if (!_csvLoaded && _csvErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Gagal memuat daftar desa: $_csvErrorMessage',
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_kecamatanOptions.isNotEmpty) ...[
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          final q = textEditingValue.text.toLowerCase();
                          if (q.isEmpty) return _kecamatanOptions;
                          return _kecamatanOptions.where(
                            (p) => p.toLowerCase().contains(q),
                          );
                        },
                        onSelected: (selection) {
                          setState(() {
                            _selectedKecamatan = selection;
                            _kecamatanCtrl.text = selection;
                            _selectedDesaKode = null;
                            _selectedDesaName = null;
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              if (textEditingController.text.isEmpty &&
                                  _kecamatanCtrl.text.isNotEmpty) {
                                textEditingController.text =
                                    _kecamatanCtrl.text;
                              }
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Kecamatan',
                                  hintText: 'Pilih kecamatan',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                                onFieldSubmitted: (_) => onFieldSubmitted(),
                              );
                            },
                      ),
                      const SizedBox(height: 12),
                      if (_selectedKecamatan != null &&
                          (_desaByKecamatan[_selectedKecamatan!] ?? [])
                              .isNotEmpty)
                        Autocomplete<String>(
                          optionsBuilder: (textEditingValue) {
                            final q = textEditingValue.text.toLowerCase();
                            final list =
                                _desaByKecamatan[_selectedKecamatan!] ?? [];
                            final List<String> desaNames = list
                                .map((m) => (m['desa'] ?? '').toString())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            desaNames.sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                            if (q.isEmpty) return desaNames;
                            return desaNames.where(
                              (d) => d.toLowerCase().contains(q),
                            );
                          },
                          onSelected: (selection) {
                            final list =
                                _desaByKecamatan[_selectedKecamatan!] ?? [];
                            final found = list.firstWhere(
                              (e) => (e['desa'] ?? '') == selection,
                              orElse: () => {'kode': ''},
                            );
                            setState(() {
                              _selectedDesaKode = found['kode'];
                              _selectedDesaName = selection;
                              _kodeCtrl.text = found['kode'] ?? '';
                              _namaCtrl.text = selection;
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                if (textEditingController.text.isEmpty &&
                                    _selectedDesaName != null) {
                                  textEditingController.text =
                                      _selectedDesaName!;
                                }
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Pilih Desa',
                                    hintText: 'Cari atau pilih desa',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Wajib dipilih';
                                    final list =
                                        _desaByKecamatan[_selectedKecamatan!] ??
                                        [];
                                    final exists = list.any(
                                      (e) =>
                                          (e['desa'] ?? '').toLowerCase() ==
                                          v.trim().toLowerCase(),
                                    );
                                    return exists
                                        ? null
                                        : 'Silakan pilih desa yang ada di daftar';
                                  },
                                  onFieldSubmitted: (_) => onFieldSubmitted(),
                                );
                              },
                        )
                      else
                        TextFormField(
                          controller: TextEditingController(),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Pilih Desa',
                            hintText: 'Pilih kecamatan terlebih dahulu',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context, null),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Batal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
    if (widget.initialKecamatan != null)
      _kecamatanCtrl.text = widget.initialKecamatan!;

    try {
      final detail = await DesaRepository().fetchDesaDetailByKode(
        widget.kodeWilayah,
      );
      if (detail != null && mounted) {
        _namaCtrl.text = (detail['nama'] ?? _namaCtrl.text) as String;
        _kecamatanCtrl.text =
            (detail['kecamatan'] ?? _kecamatanCtrl.text) as String;
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_location_alt_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Edit Desa',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Kode: ${widget.kodeWilayah}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleTextField(
                          controller: _kecamatanCtrl,
                          label: 'Kecamatan',
                          hint: 'Contoh: Kuripan',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
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
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context, null),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  _saving ? 'Menyimpan...' : 'Simpan',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      desa.nama,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
