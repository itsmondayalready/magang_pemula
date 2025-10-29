import 'package:flutter/material.dart';
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
        padding: EdgeInsets.fromLTRB(context.horizontalPadding, 0, context.horizontalPadding, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _InfoRow(label: 'Nama Desa', value: 'Desa Sukamaju'),
                _InfoRow(label: 'Kode Wilayah', value: '3201012001'),
                _InfoRow(label: 'Kecamatan', value: 'Ciwidey'),
                _InfoRow(label: 'Kabupaten', value: 'Bandung'),
                _InfoRow(label: 'Provinsi', value: 'Jawa Barat'),
                _InfoRow(label: 'Kode Pos', value: '40973'),
              ],
            ),
            const SizedBox(height: 16),

            // Kepala Desa
            _SectionCard(
              title: 'Kepala Desa',
              icon: Icons.person_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF0B7A75), Color(0xFFB08900)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              children: const [
                _InfoRow(label: 'Nama', value: 'Budi Santoso, S.Sos'),
                _InfoRow(label: 'NIP', value: '197505121998031004'),
                _InfoRow(label: 'Periode Jabatan', value: '2019 - 2025'),
                _InfoRow(label: 'No. Telepon', value: '+62 812-3456-7890'),
                _InfoRow(label: 'Email', value: 'kades.sukamaju@gmail.com'),
              ],
            ),
            const SizedBox(height: 16),

            // Geografis
            _SectionCard(
              title: 'Kondisi Geografis',
              icon: Icons.terrain_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFFA3E635)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              children: const [
                _InfoRow(label: 'Luas Wilayah', value: '12.5 km²'),
                _InfoRow(label: 'Ketinggian', value: '1.200 mdpl'),
                _InfoRow(label: 'Batas Utara', value: 'Desa Mekar Sari'),
                _InfoRow(label: 'Batas Selatan', value: 'Desa Patengan'),
                _InfoRow(label: 'Batas Timur', value: 'Desa Sindang Jaya'),
                _InfoRow(label: 'Batas Barat', value: 'Desa Alam Endah'),
              ],
            ),
            const SizedBox(height: 16),

            // Perangkat Desa
            _SectionCard(
              title: 'Perangkat Desa',
              icon: Icons.groups_3_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              children: const [
                _InfoRow(label: 'Sekretaris Desa', value: 'Siti Nurhaliza, S.Kom'),
                _InfoRow(label: 'Kaur Keuangan', value: 'Ahmad Fauzi, SE'),
                _InfoRow(label: 'Kaur Perencanaan', value: 'Dewi Sartika, S.Sos'),
                _InfoRow(label: 'Kaur Tata Usaha', value: 'Rudi Hartono, S.Pd'),
                _InfoRow(label: 'Kasi Pemerintahan', value: 'Bambang Sutrisno, S.IP'),
                _InfoRow(label: 'Kasi Kesejahteraan', value: 'Nurul Hidayah, SKM'),
                _InfoRow(label: 'Kasi Pelayanan', value: 'Eko Prasetyo, A.Md'),
              ],
            ),
            const SizedBox(height: 16),

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
                _InfoRow(label: 'Telepon Kantor', value: '(022) 5891234'),
                _InfoRow(label: 'Email Desa', value: 'info@desasukamaju.id'),
                _InfoRow(label: 'Website', value: 'www.desasukamaju.id'),
                _InfoRow(label: 'Instagram', value: '@desasukamaju'),
                _InfoRow(label: 'Facebook', value: 'Desa Sukamaju Official'),
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
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  // Dummy foto desa - nanti bisa diganti dengan URL dari Supabase
  final List<_DesaPhoto> _photos = const [
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
      caption: 'Balai Desa Sukamaju',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1590736969955-71cc94901144?w=800',
      caption: 'Pemandangan Perkebunan Teh',
    ),
    _DesaPhoto(
      url: 'https://images.unsplash.com/photo-1536431311719-398b6704d4cc?w=800',
      caption: 'Masjid Al-Ikhlas',
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
  void dispose() {
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
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _photos[index].url,
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
                            _photos[index].caption,
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
              width: _currentPage == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
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
