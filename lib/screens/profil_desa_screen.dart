import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/responsive.dart';

class ProfilDesaScreen extends StatelessWidget {
  const ProfilDesaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Desa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
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
      body: SingleChildScrollView(
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
              children: [
                _PhotoCarousel(),
              ],
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
              children: const [
                _InfoRow(label: 'Nama Desa', value: 'Desa Melayu Ilir'),
                _InfoRow(label: 'Kode Wilayah', value: '6303052009'),
                _InfoRow(label: 'Kecamatan', value: 'Martapura'),
                _InfoRow(label: 'Kabupaten', value: 'Banjar'),
                _InfoRow(label: 'Provinsi', value: 'Kalimantan Selatan'),
                _InfoRow(label: 'Jumlah RT', value: '3 RT'),
                _InfoRow(label: 'Jumlah RW', value: '1 RW'),
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
              children: const [
                _InfoRow(label: 'Kepala Desa', value: 'MURJANI'),
                _InfoRow(label: 'Sekretaris Desa', value: 'NUR LUTFIA'),
                _InfoRow(label: 'Kasi Pemerintahan', value: 'H. BUNAWAR'),
                _InfoRow(label: 'Kasi Pelayanan dan Kesejahteraan', value: 'A. JAILANI'),
                _InfoRow(label: 'Kaur Umum dan Perencanaan', value: 'FATHURRIZOAH, S.PD.I'),
                _InfoRow(label: 'Kaur Keuangan', value: 'NAFILAH'),
                _InfoRow(label: 'Kepala Lingkungan I', value: 'MUHAMMAD KADRI'),
                _InfoRow(label: 'Kepala Lingkungan II', value: 'ANDI HIDAYAT'),
                _InfoRow(label: 'Ketua BPD', value: 'RAFI\'I, S.PD.I'),
                _InfoRow(label: 'Wakil Ketua BPD', value: 'PITRIANI'),
                _InfoRow(label: 'Sekretaris BPD', value: 'SRI MULIYANI, S.PD'),
                _InfoRow(label: 'Anggota BPD', value: 'RAHMADI'),
                _InfoRow(label: 'Anggota BPD', value: 'SAUFI, S.E'),
                _InfoRow(label: 'Ketua RT I', value: 'AHMAD MUJAHIT'),
                _InfoRow(label: 'Ketua RT II', value: 'M. HATTA'),
                _InfoRow(label: 'Ketua RT III', value: 'H. SYA\'RANI'),
              ],
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
              children: const [
                _InfoRow(label: 'Nama Desa', value: 'Desa Melayu Ilir'),
                _InfoRow(label: 'Kecamatan', value: 'Martapura'),
                _InfoRow(label: 'Kabupaten', value: 'Banjar'),
                _InfoRow(label: 'Provinsi', value: 'Kalimantan Selatan'),
                _InfoRow(label: 'Total Aparatur', value: '13 Orang (termasuk BPD dan RT)'),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk baris informasi
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk carousel foto desa
class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel();

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  // Dummy foto desa - nanti bisa diganti dengan URL dari Supabase
  final List<_DesaPhoto> _photos = const [
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
      caption: 'Balai Desa Melayu Ilir',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1590736969955-71cc94901144?w=800',
      caption: 'Pemandangan Desa',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1536431311719-398b6704d4cc?w=800',
      caption: 'Masjid Desa',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800',
      caption: 'Kegiatan Gotong Royong',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1513366884929-f0b3d46eee4b?w=800',
      caption: 'Festival Desa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final len = _photos.length;
    final initialPage = len * 1000; // Start at a large number for infinite scroll
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialPage,
    );
    _currentPage = initialPage;
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _currentPage + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              final photoIndex = index % _photos.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _photos[photoIndex].url,
                        fit: BoxFit.cover,
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
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _photos[photoIndex].caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
            _photos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: (_currentPage % _photos.length) == index ? 18 : 6,
              decoration: BoxDecoration(
                color: (_currentPage % _photos.length) == index
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

class _DesaPhoto {
  final String url;
  final String caption;

  const _DesaPhoto({
    required this.url,
    required this.caption,
  });
}
