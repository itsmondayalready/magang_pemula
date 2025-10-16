import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Main menu screen untuk aplikasi Desa — versi yang dirapikan
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

  @override
  void initState() {
    super.initState();
    _desaName = widget.desaName;
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
      setState(() {
        _desaName = selected.nama;
        // TODO: update kodeWilayah juga jika perlu
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature(
        title: 'Rencana',
        subtitle: 'Program & Kegiatan',
        icon: Icons.playlist_add_check_rounded,
        gradient: _gradEmeraldGold,
        route: '/rencana',
      ),
      _Feature(
        title: 'Riwayat',
        subtitle: 'Monografi bulanan',
        icon: Icons.history_rounded,
        gradient: _gradTealIndigo,
        route: '/riwayat',
      ),
      _Feature(
        title: 'Kalender',
        subtitle: 'Kegiatan & Jadwal',
        icon: Icons.event_rounded,
        gradient: _gradOrangePink,
        route: '/kalender',
      ),
      _Feature(
        title: 'Kuesioner',
        subtitle: 'Umpan balik warga',
        icon: Icons.fact_check_rounded,
        gradient: _gradBluePurple,
        route: '/kuesioner',
      ),
      _Feature(
        title: 'Profil Desa',
        subtitle: 'Info pemerintahan',
        icon: Icons.account_balance_rounded,
        gradient: _gradEmeraldBlue,
        route: '/profil',
      ),
      _Feature(
        title: 'Kependudukan',
        subtitle: 'Komposisi & tren',
        icon: Icons.people_alt_rounded,
        gradient: _gradCyanBlue,
        route: '/kependudukan',
      ),
      _Feature(
        title: 'Kebencanaan',
        subtitle: 'Banjir & laporan',
        icon: Icons.warning_amber_rounded,
        gradient: _gradRedOrange,
        route: '/kebencanaan',
      ),
      _Feature(
        title: 'Sarana',
        subtitle: 'Pendidikan, kesehatan',
        icon: Icons.room_preferences_rounded,
        gradient: _gradGreenLime,
        route: '/sarana',
      ),
      _Feature(
        title: 'Komunikasi',
        subtitle: 'Internet & kanal publikasi',
        icon: Icons.wifi_rounded,
        gradient: _gradIndigoCyan,
        route: '/komunikasi',
      ),
      _Feature(
        title: 'Ekonomi',
        subtitle: 'Perdagangan & keuangan',
        icon: Icons.store_mall_directory_rounded,
        gradient: _gradGoldBrown,
        route: '/ekonomi',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _MainMenuHeaderDelegate(
              desaName: _desaName,
              kodeWilayah: widget.kodeWilayah,
              isAdmin: widget.isAdmin,
              onChangeWilayah: _changeWilayah,
              onLogout: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                await auth.signOut();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderStats(totalPenduduk: widget.totalPenduduk, totalKK: widget.totalKK),
                  const SizedBox(height: 12),
                  // Small top menu stays in the body (horizontal carousel)
                  const _TopMenuCarousel(),
                  const SizedBox(height: 10),
                  _SearchField(onChanged: (v) {/* TODO: implement search */}),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: _FeatureGrid(features: features),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (_) => const _QuickActionsSheet(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Aksi Cepat'),
      ),
    );
  }
}

class _MainMenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String desaName;
  final String kodeWilayah;
  final bool isAdmin;
  final VoidCallback onChangeWilayah;
  final VoidCallback onLogout;
  _MainMenuHeaderDelegate({
    required this.desaName,
    required this.kodeWilayah,
    required this.isAdmin,
    required this.onChangeWilayah,
    required this.onLogout,
  });

  @override
  double get minExtent => 140;
  @override
  double get maxExtent => 180;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
  // header content delegates animation handling to _HeaderContent
    return Container(
      decoration: const BoxDecoration(
        gradient: _gradLogin,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: _HeaderContent(
        desaName: desaName,
        kodeWilayah: kodeWilayah,
        isAdmin: isAdmin,
        onChangeWilayah: onChangeWilayah,
        onLogout: onLogout,
        shrinkOffset: shrinkOffset,
        minExtent: minExtent,
        maxExtent: maxExtent,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MainMenuHeaderDelegate oldDelegate) {
    return desaName != oldDelegate.desaName || kodeWilayah != oldDelegate.kodeWilayah || isAdmin != oldDelegate.isAdmin;
  }
}

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

class _HeaderContentState extends State<_HeaderContent> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..value = 1.0;
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant _HeaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shrinkRange = widget.maxExtent - widget.minExtent;
    final factor = shrinkRange > 0 ? (widget.shrinkOffset / shrinkRange).clamp(0.0, 1.0) : 0.0;
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Text(
                                'Ubah Wilayah',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
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
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
                        Text(
                          'Kode: ${widget.kodeWilayah}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _fade,
                          child: Row(
                            children: [
                              const Text('Peran', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(width: 8),
                              _AdminBadgeCompact(isAdmin: widget.isAdmin),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: widget.onLogout,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMenuItem extends StatelessWidget {
  const _TopMenuItem({required this.icon, required this.label, required this.onTap, required this.gradient});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  @override
  Widget build(BuildContext context) {
    // fixed readable label color for small menu items
    final color = Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// The rest of the helper widgets/classes are included below (trimmed and improved)
class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.totalPenduduk, required this.totalKK});
  final int totalPenduduk;
  final int totalKK;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradLogin,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan Desa',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatChip(icon: Icons.people_alt_rounded, label: 'Penduduk', value: totalPenduduk),
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.home_rounded, label: 'KK', value: totalKK),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.landscape_rounded, color: Colors.white, size: 42),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text('$label: $value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari menu, data, atau RT…',
          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});
  final List<_Feature> features;
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final f = features[i];
          return _FeatureCard(feature: f);
        },
        childCount: features.length,
      ),
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
      onTap: () => Navigator.of(context).pushNamed(feature.route),
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
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
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
              const SizedBox(height: 4),
              Text(
                feature.subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;
  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
  });
}

// _AdminBadge removed — replaced by _AdminBadgeCompact for compact/consistent use

// Compact variant of the admin badge used in the smaller header
class _AdminBadgeCompact extends StatelessWidget {
  const _AdminBadgeCompact({required this.isAdmin});
  final bool isAdmin;
  @override
  Widget build(BuildContext context) {
    final baseColor = isAdmin ? Colors.green : Colors.grey;
    final bgColor = isAdmin ? baseColor.withValues(alpha: 0.18) : baseColor.withValues(alpha: 0.10);
    final borderColor = baseColor.withValues(alpha: 0.28);
    final contentColor = isAdmin ? Colors.white : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: contentColor, size: 14),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Admin' : 'Guest',
            style: TextStyle(color: contentColor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet();
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(Icons.note_add_rounded, 'Tambah Rencana', '/rencana', _gradEmeraldGold),
      _ActionData(Icons.campaign_rounded, 'Catat Kebencanaan', '/kebencanaan', _gradRedOrange),
      _ActionData(Icons.event_available_rounded, 'Buat Jadwal', '/kalender', _gradOrangePink),
      _ActionData(Icons.how_to_vote_rounded, 'Buat Kuesioner', '/kuesioner', _gradBluePurple),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aksi Cepat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...actions.map((a) => ListTile(
                  leading: Icon(a.icon),
                  title: Text(a.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, a.route);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final String route;
  final Gradient gradient;
  const _ActionData(this.icon, this.label, this.route, this.gradient);
}

class _TopMenuCarousel extends StatelessWidget {
  const _TopMenuCarousel();
  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionData(Icons.book_rounded, 'Publikasi', '/publikasi', _gradBluePurple),
      _ActionData(Icons.table_chart_rounded, 'Tabel', '/tabel', _gradTealIndigo),
      _ActionData(Icons.image_rounded, 'Infografis', '/infografis', _gradIndigoCyan),
      _ActionData(Icons.insert_drive_file_rounded, 'BRS', '/brs', _gradGoldBrown),
      _ActionData(Icons.people_rounded, 'Kependudukan', '/kependudukan', _gradCyanBlue),
      _ActionData(Icons.warning_rounded, 'Kebencanaan', '/kebencanaan', _gradRedOrange),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _TopMenuItem(
              icon: it.icon,
              label: it.label,
              onTap: () => Navigator.pushNamed(context, it.route),
              gradient: it.gradient,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemCount: items.length,
      ),
    );
  }
}

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

// Data dummy desa - nanti diganti dengan data dari Firestore
final _dummyDesaList = <_DesaData>[
  _DesaData(nama: 'Desa Sukamaju', kode: '3201012001', kecamatan: 'Ciwidey', penduduk: 5420),
  _DesaData(nama: 'Desa Mekar Sari', kode: '3201012002', kecamatan: 'Ciwidey', penduduk: 4230),
  _DesaData(nama: 'Desa Sindang Jaya', kode: '3201012003', kecamatan: 'Pasir Jambu', penduduk: 6150),
  _DesaData(nama: 'Desa Cibodas', kode: '3201012004', kecamatan: 'Rancabali', penduduk: 3890),
  _DesaData(nama: 'Desa Alam Endah', kode: '3201012005', kecamatan: 'Ciwidey', penduduk: 7200),
  _DesaData(nama: 'Desa Patengan', kode: '3201012006', kecamatan: 'Rancabali', penduduk: 2450),
  _DesaData(nama: 'Desa Sukamanah', kode: '3201012007', kecamatan: 'Pasir Jambu', penduduk: 5630),
  _DesaData(nama: 'Desa Nengkelan', kode: '3201012008', kecamatan: 'Ciwidey', penduduk: 4120),
  _DesaData(nama: 'Desa Rawabogo', kode: '3201012009', kecamatan: 'Rancabali', penduduk: 3340),
  _DesaData(nama: 'Desa Cipanjalu', kode: '3201012010', kecamatan: 'Pasir Jambu', penduduk: 4890),
];

class _DesaPickerSheet extends StatefulWidget {
  const _DesaPickerSheet();

  @override
  State<_DesaPickerSheet> createState() => _DesaPickerSheetState();
}

class _DesaPickerSheetState extends State<_DesaPickerSheet> {
  final _searchController = TextEditingController();
  List<_DesaData> _filteredList = _dummyDesaList;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDesa(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _dummyDesaList;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredList = _dummyDesaList.where((desa) {
          return desa.nama.toLowerCase().contains(lowercaseQuery) ||
              desa.kecamatan.toLowerCase().contains(lowercaseQuery) ||
              desa.kode.contains(query);
        }).toList();
      }
    });
  }

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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Desa list
            Expanded(
              child: _filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada desa ditemukan',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final desa = _filteredList[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _gradLogin,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_city_rounded, color: Colors.white),
                          ),
                          title: Text(
                            desa.nama,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kec. ${desa.kecamatan} • ${desa.kode}'),
                              const SizedBox(height: 2),
                              Text(
                                '${desa.penduduk} penduduk',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
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
const _gradTealIndigo = LinearGradient(
  colors: [Color(0xFF0EA5A5), Color(0xFF4338CA)],
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
const _gradEmeraldBlue = LinearGradient(
  colors: [Color(0xFF059669), Color(0xFF2563EB)],
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
const _gradIndigoCyan = LinearGradient(
  colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _gradGoldBrown = LinearGradient(
  colors: [Color(0xFFB45309), Color(0xFF92400E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
