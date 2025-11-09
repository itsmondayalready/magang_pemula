import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/responsive.dart';
import '../services/desa_repository.dart';
import '../services/auth_service.dart';

class ProfilDesaScreen extends StatefulWidget {
  const ProfilDesaScreen({
    super.key,
    required this.kodeWilayah,
    required this.desaName,
  });
  final String kodeWilayah;
  final String desaName;

  @override
  State<ProfilDesaScreen> createState() => _ProfilDesaScreenState();
}

class _ProfilDesaScreenState extends State<ProfilDesaScreen> {
  final _repo = DesaRepository();
  bool _loading = true;
  bool _hasChanges = false; // Track if any data was modified
  List<Map<String, dynamic>> _aparatur = const [];
  List<DesaPhoto> _photos = []; // Dynamic list from database
  String? _kecamatan;
  String? _kabupaten;
  String? _provinsi;
  int? _totalRT;
  int? _totalRW;
  double? _luasKm2;
  String? _teleponKantor;
  String? _emailKantor;
  String? _website;
  Map<String, dynamic>? _sosmed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Future(() async {
        final detail = await _repo.fetchDesaDetailByKode(widget.kodeWilayah);
        if (detail != null) {
          _kecamatan = detail['kecamatan'] as String?;
          _kabupaten = detail['kabupaten'] as String?;
          _provinsi = detail['provinsi'] as String?;
          final p = detail['desa_profile'] as Map<String, dynamic>?;
          _totalRT = p?['total_rt'] as int?;
          _totalRW = p?['total_rw'] as int?;
          _luasKm2 = (p?['luas_wilayah'] as num?)?.toDouble();
          _teleponKantor = p?['telepon_kantor'] as String?;
          _emailKantor = p?['email_kantor'] as String?;
          _website = p?['website'] as String?;
          final sos = p?['sosmed'];
          if (sos is Map<String, dynamic>) {
            _sosmed = sos;
          } else {
            _sosmed = null;
          }
        }

        // Load aparatur desa
        _aparatur = await _repo.fetchAparaturByKode(widget.kodeWilayah);

        // Load galeri foto
        _photos = await _repo.fetchGaleriFoto(widget.kodeWilayah);

        if (mounted) setState(() {});
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // timeout: leave values null and proceed to show placeholders
    } catch (_) {
      // ignore
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  String _formatSosmed(Map<String, dynamic>? s) {
    if (s == null || s.isEmpty) return '—';
    final parts = <String>[];
    void addIf(String key, String label) {
      final v = s[key];
      if (v is String && v.trim().isNotEmpty) parts.add('$label: $v');
    }

    addIf('ig', 'IG');
    addIf('facebook', 'FB');
    addIf('yt', 'YT');
    addIf('tiktok', 'TT');
    addIf('x', 'X');
    return parts.isEmpty ? '—' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isAdmin = authService.isSignedIn && authService.isAdmin;

    return WillPopScope(
      onWillPop: () async {
        // Return _hasChanges flag to main menu for conditional refresh
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profil Desa',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              16,
              context.horizontalPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galeri Foto Desa
                _SectionCard(
                  title: 'Galeri Foto Desa',
                  icon: Icons.photo_library_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [_PhotoCarousel(photos: _photos)],
                ),
                const SizedBox(height: 16),

                // Identitas Desa
                _SectionCard(
                  title: 'Identitas Desa',
                  icon: Icons.location_city_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [
                    _InfoRow(label: 'Nama Desa', value: widget.desaName),
                    _InfoRow(label: 'Kode Wilayah', value: widget.kodeWilayah),
                    _InfoRow(label: 'Kecamatan', value: _kecamatan ?? '—'),
                    _InfoRow(label: 'Kabupaten', value: _kabupaten ?? '—'),
                    _InfoRow(label: 'Provinsi', value: _provinsi ?? '—'),
                    _InfoRow(
                      label: 'Jumlah RT',
                      value: _totalRT != null ? '$_totalRT RT' : '—',
                    ),
                    _InfoRow(
                      label: 'Jumlah RW',
                      value: _totalRW != null ? '$_totalRW RW' : '—',
                    ),
                    if (_luasKm2 != null)
                      _InfoRow(
                        label: 'Luas Wilayah',
                        value: '${_luasKm2!.toStringAsFixed(2)} km²',
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Aparatur Desa
                _SectionCard(
                  title: 'Aparatur Desa',
                  icon: Icons.groups_3_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: _aparatur.isEmpty
                      ? const [_InfoRow(label: '—', value: 'Belum ada data')]
                      : _aparatur
                            .map(
                              (a) => _InfoRow(
                                label: (a['jabatan'] as String?) ?? '—',
                                value: (a['nama'] as String?) ?? '—',
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 16),

                // Kontak & Sosial Media
                _SectionCard(
                  title: 'Kontak & Informasi',
                  icon: Icons.contact_phone_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [
                    _InfoRow(
                      label: 'Telepon Kantor',
                      value: _teleponKantor ?? '—',
                    ),
                    _InfoRow(label: 'Email Kantor', value: _emailKantor ?? '—'),
                    _InfoRow(label: 'Website', value: _website ?? '—'),
                    _InfoRow(
                      label: 'Sosial Media',
                      value: _formatSosmed(_sosmed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
                      Color(0xFF9333EA), // purple
                      Color(0xFFEC4899), // pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x409333EA),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, color: Colors.white),
              ),
            )
          : null,
      ), // Scaffold
    ); // WillPopScope
  }

  Future<void> _openEditBottomSheet() async {
    if (!mounted) return;

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _EditBottomSheet(
          kodeWilayah: widget.kodeWilayah,
          desaName: widget.desaName,
          totalRT: _totalRT,
          totalRW: _totalRW,
          luasWilayah: _luasKm2,
          teleponKantor: _teleponKantor,
          emailKantor: _emailKantor,
          website: _website,
          sosmed: _sosmed,
          aparaturList: _aparatur,
          existingPhotos: _photos.map((p) => p.path).toList(),
        ),
      );

      // Reload jika ada perubahan
      if (result == true && mounted) {
        _hasChanges = true; // Mark that data was modified
        setState(() {
          _loading = true;
        });
        await _load();
      }
    } catch (e) {
      print('ModalBottomSheet error: $e');
    }
  }
}

// Widget untuk section card dengan gradient header
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Gradient gradient;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// Widget untuk baris informasi
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk carousel foto desa
class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photos});

  final List<DesaPhoto> photos;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  PageController? _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(_PhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika photos berubah dari kosong ke ada isi, initialize controller
    if (oldWidget.photos.isEmpty && widget.photos.isNotEmpty) {
      _initializeController();
    }
    // Jika photos berubah dari ada isi ke kosong, dispose controller
    else if (oldWidget.photos.isNotEmpty && widget.photos.isEmpty) {
      _disposeController();
    }
  }

  void _initializeController() {
    if (widget.photos.isEmpty) return;

    _disposeController(); // Dispose dulu jika ada

    final len = widget.photos.length;
    final initialPage = len * 1000;
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialPage,
    );
    _currentPage = initialPage;
    _startAutoScroll();
  }

  void _disposeController() {
    _timer?.cancel();
    _timer = null;
    _pageController?.dispose();
    _pageController = null;
  }

  void _startAutoScroll() {
    if (widget.photos.isEmpty || _pageController == null) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController?.hasClients ?? false) {
        final nextPage = _currentPage + 1;
        _pageController?.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    // Empty state - Responsif dengan padding dan ukuran yang menyesuaikan
    if (widget.photos.isEmpty || _pageController == null) {
      return Container(
        height: isTablet ? 250 : 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: isTablet ? 56 : 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Belum Ada Galeri Foto',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40 : 20,
                  ),
                  child: Text(
                    'Galeri foto desa akan ditampilkan di sini ketika sudah tersedia',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isTablet ? 14 : 12,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: null, // Infinite scroll
            itemBuilder: (context, index) {
              final photoIndex = index % widget.photos.length;
              final photo = widget.photos[photoIndex];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Error loading image: $error');
                          debugPrint('📸 Image URL: ${photo.url}');
                          debugPrint('📁 Image path: ${photo.path}');
                          return Container(
                            color: Colors.grey.shade300,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image_rounded,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Gagal memuat foto',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        photo.path,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.photos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: (_currentPage % widget.photos.length) == index ? 18 : 6,
              decoration: BoxDecoration(
                color: (_currentPage % widget.photos.length) == index
                    ? const Color(0xFF9333EA)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Edit Bottom Sheet dengan 3 tabs
class _EditBottomSheet extends StatefulWidget {
  const _EditBottomSheet({
    required this.kodeWilayah,
    required this.desaName,
    required this.totalRT,
    required this.totalRW,
    required this.luasWilayah,
    required this.teleponKantor,
    required this.emailKantor,
    required this.website,
    required this.sosmed,
    required this.aparaturList,
    required this.existingPhotos,
  });

  final String kodeWilayah;
  final String desaName;
  final int? totalRT;
  final int? totalRW;
  final double? luasWilayah;
  final String? teleponKantor;
  final String? emailKantor;
  final String? website;
  final Map<String, dynamic>? sosmed;
  final List<Map<String, dynamic>> aparaturList;
  final List<String> existingPhotos;

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = DesaRepository();
  final _picker = ImagePicker();
  bool _saving = false;
  bool _uploadingPhoto = false;

  // Identitas controllers
  late final TextEditingController _totalRTCtl;
  late final TextEditingController _totalRWCtl;
  late final TextEditingController _luasWilayahCtl;

  // Kontak controllers
  late final TextEditingController _teleponCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _websiteCtl;
  late final TextEditingController _igCtl;
  late final TextEditingController _facebookCtl;
  late final TextEditingController _ytCtl;
  late final TextEditingController _tiktokCtl;
  late final TextEditingController _xCtl;

  // Aparatur list
  late List<_AparaturItem> _aparaturList;
  
  // Galeri photos
  List<String> _existingPhotos = [];
  List<XFile> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Ubah dari 3 ke 4

    // Initialize identitas controllers
    _totalRTCtl = TextEditingController(text: widget.totalRT?.toString() ?? '');
    _totalRWCtl = TextEditingController(text: widget.totalRW?.toString() ?? '');
    _luasWilayahCtl = TextEditingController(text: widget.luasWilayah?.toString() ?? '');

    // Initialize kontak controllers
    _teleponCtl = TextEditingController(text: widget.teleponKantor ?? '');
    _emailCtl = TextEditingController(text: widget.emailKantor ?? '');
    _websiteCtl = TextEditingController(text: widget.website ?? '');
    _igCtl = TextEditingController(text: widget.sosmed?['ig'] as String? ?? '');
    _facebookCtl = TextEditingController(text: widget.sosmed?['facebook'] as String? ?? '');
    _ytCtl = TextEditingController(text: widget.sosmed?['yt'] as String? ?? '');
    _tiktokCtl = TextEditingController(text: widget.sosmed?['tiktok'] as String? ?? '');
    _xCtl = TextEditingController(text: widget.sosmed?['x'] as String? ?? '');

    // Initialize aparatur list
    _aparaturList = widget.aparaturList
        .map((a) => _AparaturItem(
              id: a['id'] as String?,
              kategori: (a['kategori'] as String?) ?? 'perangkat',
              jabatan: (a['jabatan'] as String?) ?? '',
              nama: (a['nama'] as String?) ?? '',
              urutan: a['urutan'] as int?,
            ))
        .toList();
    
    // Initialize existing photos
    _existingPhotos = List.from(widget.existingPhotos);
    
    // Normalisasi urutan saat init
    _normalizeUrutan();
  }
  
  // Helper function untuk normalisasi urutan
  void _normalizeUrutan() {
    final activeItems = _aparaturList.where((a) => !a.removed).toList();
    activeItems.sort((a, b) => (a.urutan ?? 0).compareTo(b.urutan ?? 0));
    for (int i = 0; i < activeItems.length; i++) {
      activeItems[i].urutan = i + 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalRTCtl.dispose();
    _totalRWCtl.dispose();
    _luasWilayahCtl.dispose();
    _teleponCtl.dispose();
    _emailCtl.dispose();
    _websiteCtl.dispose();
    _igCtl.dispose();
    _facebookCtl.dispose();
    _ytCtl.dispose();
    _tiktokCtl.dispose();
    _xCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Edit Profil Desa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.desaName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // TabBar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Identitas'),
              Tab(text: 'Aparatur'),
              Tab(text: 'Kontak'),
              Tab(text: 'Galeri'),
            ],
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIdentitasTab(),
                _buildAparaturTab(),
                _buildKontakTab(),
                _buildGaleriTab(),
              ],
            ),
          ),

          // Save Button
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
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
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
    );
  }

  Widget _buildIdentitasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField('Jumlah RT', _totalRTCtl, TextInputType.number),
        _buildTextField('Jumlah RW', _totalRWCtl, TextInputType.number),
        _buildTextField(
          'Luas Wilayah (km²)',
          _luasWilayahCtl,
          const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildAparaturTab() {
    return Column(
      children: [
        Expanded(
          child: _aparaturList.where((item) => !item.removed).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada aparatur',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Tambah padding bottom untuk button sticky
                  itemCount: _aparaturList.length,
                  itemBuilder: (context, index) {
                    final item = _aparaturList[index];
                    if (item.removed) return const SizedBox.shrink();
                    
                    return _AparaturCard(
                      item: item,
                      index: index,
                      onDelete: () {
                        setState(() {
                          item.removed = true;
                          _normalizeUrutan();
                        });
                      },
                    );
                  },
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
                // Tambah aparatur baru di akhir
                _aparaturList.add(_AparaturItem(
                  id: null,
                  kategori: 'perangkat',
                  jabatan: '',
                  nama: '',
                  urutan: 999, // Temporary, akan dinormalisasi
                ));
                
                // Normalisasi urutan agar berurutan 1, 2, 3...
                _normalizeUrutan();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Aparatur'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKontakTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Kontak Kantor
        Text(
          'Kontak Kantor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField('Telepon Kantor', _teleponCtl, TextInputType.phone),
        _buildTextField('Email Kantor', _emailCtl, TextInputType.emailAddress),
        _buildTextField('Website', _websiteCtl, TextInputType.url),

        const SizedBox(height: 24),

        // Section Sosial Media
        Text(
          'Sosial Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField('Instagram', _igCtl, TextInputType.text, hintText: '@username'),
        _buildTextField('Facebook', _facebookCtl, TextInputType.text),
        _buildTextField('YouTube', _ytCtl, TextInputType.text),
        _buildTextField('TikTok', _tiktokCtl, TextInputType.text, hintText: '@username'),
        _buildTextField('X (Twitter)', _xCtl, TextInputType.text, hintText: '@username'),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
            borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGaleriTab() {
    return Column(
      children: [
        Expanded(
          child: _existingPhotos.isEmpty && _newPhotos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada foto',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap tombol tambah di bawah untuk upload foto',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _existingPhotos.length + _newPhotos.length,
                  itemBuilder: (context, index) {
                    if (index < _existingPhotos.length) {
                      // Existing photo from Supabase
                      final photoPath = _existingPhotos[index];
                      final url = _repo.getPhotoUrl(photoPath);
                      return _buildPhotoCard(url, index, isNew: false);
                    } else {
                      // New photo to be uploaded
                      final newIndex = index - _existingPhotos.length;
                      final file = _newPhotos[newIndex];
                      return _buildNewPhotoCard(file, index);
                    }
                  },
                ),
        ),
        // Sticky button untuk tambah foto
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
            onPressed: _uploadingPhoto ? null : _pickImage,
            icon: _uploadingPhoto
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate),
            label: Text(_uploadingPhoto ? 'Uploading...' : 'Tambah Foto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(String url, int index, {required bool isNew}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () {
                setState(() {
                  if (isNew) {
                    _newPhotos.removeAt(index - _existingPhotos.length);
                  } else {
                    _existingPhotos.removeAt(index);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPhotoCard(XFile file, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () {
                setState(() {
                  _newPhotos.removeAt(index - _existingPhotos.length);
                });
              },
            ),
          ),
        ),
        // Badge "NEW"
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      print('📸 [PICK] Opening image picker...');
      
      // Try multiple images first
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      
      print('📸 [PICK] Selected ${images.length} images');
      
      if (images.isNotEmpty) {
        setState(() {
          _newPhotos.addAll(images);
        });
        print('✅ [PICK] Added ${images.length} images to _newPhotos');
      } else {
        print('⚠️ [PICK] No images selected');
      }
    } catch (e) {
      print('❌ [PICK] Error with pickMultiImage: $e');
      
      // Fallback: try single image
      try {
        print('📸 [PICK] Trying single image picker...');
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        
        if (image != null) {
          setState(() {
            _newPhotos.add(image);
          });
          print('✅ [PICK] Added single image to _newPhotos');
        }
      } catch (e2) {
        print('❌ [PICK] Error with pickImage: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memilih foto: $e2'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      print('🔍 [SAVE] Starting save process...');
      
      final desa = await _repo.fetchDesaDetailByKode(widget.kodeWilayah);
      if (desa == null) throw Exception('Desa tidak ditemukan');
      
      final desaId = desa['id'] as String;
      final profile = desa['desa_profile'];
      
      print('🔍 [SAVE] Desa ID: $desaId');
      print('🔍 [SAVE] Profile exists: ${profile != null}');

      // Prepare identitas & kontak data
      final data = <String, dynamic>{};
      
      final totalRT = int.tryParse(_totalRTCtl.text.trim());
      final totalRW = int.tryParse(_totalRWCtl.text.trim());
      final luasWilayah = double.tryParse(_luasWilayahCtl.text.trim());
      
      if (totalRT != null) data['total_rt'] = totalRT;
      if (totalRW != null) data['total_rw'] = totalRW;
      if (luasWilayah != null) data['luas_wilayah'] = luasWilayah;
      
      data['telepon_kantor'] = _teleponCtl.text.trim();
      data['email_kantor'] = _emailCtl.text.trim();
      data['website'] = _websiteCtl.text.trim();
      
      data['sosmed'] = {
        'ig': _igCtl.text.trim(),
        'facebook': _facebookCtl.text.trim(),
        'yt': _ytCtl.text.trim(),
        'tiktok': _tiktokCtl.text.trim(),
        'x': _xCtl.text.trim(),
      };

      print('🔍 [SAVE] Profile data: $data');

      // Save profile
      if (profile == null) {
        print('🔍 [SAVE] Creating new profile...');
        data['desa_id'] = desaId;
        await _repo.createDesaProfile(data);
        print('✅ [SAVE] Profile created');
      } else {
        print('🔍 [SAVE] Updating existing profile...');
        await _repo.updateDesaProfile(desaId, data);
        print('✅ [SAVE] Profile updated');
      }

      // Save aparatur
      print('🔍 [SAVE] Processing ${_aparaturList.length} aparatur items...');
      
      // Hapus aparatur yang di-remove
      for (final item in _aparaturList.where((a) => a.removed)) {
        if (item.id != null) {
          print('🔍 [SAVE] Deleting aparatur: ${item.id}');
          await _repo.deleteAparatur(item.id!);
          print('✅ [SAVE] Aparatur deleted');
        }
      }
      
      // Normalisasi urutan: ambil yang tidak di-remove, urutkan, lalu beri urutan baru 1,2,3...
      final activeAparatur = _aparaturList.where((a) => !a.removed).toList();
      activeAparatur.sort((a, b) => (a.urutan ?? 0).compareTo(b.urutan ?? 0));
      
      for (int i = 0; i < activeAparatur.length; i++) {
        final item = activeAparatur[i];
        final normalizedUrutan = i + 1; // Urutan baru: 1, 2, 3, 4, ...
        
        final aparaturData = {
          'desa_id': desaId,
          'kategori': item.kategori,
          'jabatan': item.jabatanCtl.text.trim(),
          'nama': item.namaCtl.text.trim(),
          'urutan': normalizedUrutan,
        };

        if (item.id == null) {
          print('🔍 [SAVE] Inserting new aparatur (urutan $normalizedUrutan): ${aparaturData['nama']}');
          await _repo.insertAparatur(aparaturData);
          print('✅ [SAVE] Aparatur inserted');
        } else {
          print('🔍 [SAVE] Updating aparatur (urutan $normalizedUrutan): ${item.id} - ${aparaturData['nama']}');
          await _repo.updateAparatur(item.id!, aparaturData);
          print('✅ [SAVE] Aparatur updated');
        }
      }

      // Upload new photos dan update galeri_photos
      print('🔍 [SAVE] Processing photos...');
      final allPhotoPaths = List<String>.from(_existingPhotos);
      
      if (_newPhotos.isNotEmpty) {
        print('🔍 [SAVE] Uploading ${_newPhotos.length} new photos...');
        setState(() => _uploadingPhoto = true);
        
        for (final photo in _newPhotos) {
          try {
            final file = File(photo.path);
            final uploadedPath = await _repo.uploadPhoto(widget.kodeWilayah, file);
            allPhotoPaths.add(uploadedPath);
            print('✅ [SAVE] Photo uploaded: $uploadedPath');
          } catch (e) {
            print('❌ [SAVE] Failed to upload photo: $e');
            // Continue dengan foto lainnya
          }
        }
        
        setState(() => _uploadingPhoto = false);
      }
      
      // Update galeri_photos di database
      if (allPhotoPaths.isNotEmpty || _newPhotos.isNotEmpty) {
        print('🔍 [SAVE] Updating galeri_photos with ${allPhotoPaths.length} photos...');
        await _repo.updateGaleriPhotos(desaId, allPhotoPaths);
        print('✅ [SAVE] Galeri photos updated');
      }

      print('✅ [SAVE] All data saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 16),
                ),
                const SizedBox(width: 12),
                const Text('Profil desa berhasil disimpan'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        print('🔍 [SAVE] Closing bottom sheet with result: true');
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('❌ [SAVE] Error: $e');
      print('❌ [SAVE] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      print('🔍 [SAVE] Save process completed');
    }
  }
}

// Helper class untuk aparatur item
class _AparaturItem {
  final String? id;
  String kategori;
  final TextEditingController jabatanCtl;
  final TextEditingController namaCtl;
  int? urutan;
  bool removed = false;

  _AparaturItem({
    required this.id,
    required this.kategori,
    required String jabatan,
    required String nama,
    required this.urutan,
  })  : jabatanCtl = TextEditingController(text: jabatan),
        namaCtl = TextEditingController(text: nama);
}

// Aparatur card widget
class _AparaturCard extends StatefulWidget {
  const _AparaturCard({
    required this.item,
    required this.index,
    required this.onDelete,
  });

  final _AparaturItem item;
  final int index;
  final VoidCallback onDelete;

  @override
  State<_AparaturCard> createState() => _AparaturCardState();
}

class _AparaturCardState extends State<_AparaturCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row pertama: badge urutan, kategori, delete
            Row(
              children: [
                // Badge urutan
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 10,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.item.urutan}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 14 : 13,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 8),
                // Kategori dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.item.kategori,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
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
                          borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 14 : 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'perangkat', child: Text('Perangkat Desa')),
                        DropdownMenuItem(value: 'rt', child: Text('Pengurus RT/RW')),
                        DropdownMenuItem(value: 'bpd', child: Text('BPD')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            widget.item.kategori = val;
                          });
                        }
                      },
                    ),
                  ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: isTablet ? 24 : 20,
                  ),
                  tooltip: 'Hapus',
                ),
              ],
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Jabatan dan Nama bisa side-by-side di tablet
            if (isTablet)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.item.jabatanCtl,
                      decoration: InputDecoration(
                        labelText: 'Jabatan',
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
                          borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: widget.item.namaCtl,
                      decoration: InputDecoration(
                        labelText: 'Nama',
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
                          borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Mobile & Tablet: Stack vertical
              Column(
                children: [
                  TextField(
                    controller: widget.item.jabatanCtl,
                    decoration: InputDecoration(
                      labelText: 'Jabatan',
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
                        borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isTablet ? 18 : 16,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  TextField(
                    controller: widget.item.namaCtl,
                    decoration: InputDecoration(
                      labelText: 'Nama',
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
                        borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isTablet ? 18 : 16,
                      ),
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
