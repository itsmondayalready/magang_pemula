import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Main menu screen untuk aplikasi Desa — versi yang dirapikan
class MainMenuPage extends StatelessWidget {
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
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desaName, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Kode: $kodeWilayah', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              await auth.signOut();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AdminBadge(isAdmin: isAdmin),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderStats(totalPenduduk: totalPenduduk, totalKK: totalKK),
                  const SizedBox(height: 12),
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

// The rest of the helper widgets/classes are included below (trimmed and improved)
class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.totalPenduduk, required this.totalKK});
  final int totalPenduduk;
  final int totalKK;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradEmeraldGold,
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
          Text('$label: $value', style: const TextStyle(color: Colors.white)),
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
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari menu, data, atau RT…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.isAdmin});
  final bool isAdmin;
  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? Colors.green : Colors.grey;
    final label = isAdmin ? 'Admin' : 'Guest';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
      _ActionData(Icons.note_add_rounded, 'Tambah Rencana', '/rencana'),
      _ActionData(Icons.campaign_rounded, 'Catat Kebencanaan', '/kebencanaan'),
      _ActionData(Icons.event_available_rounded, 'Buat Jadwal', '/kalender'),
      _ActionData(Icons.how_to_vote_rounded, 'Buat Kuesioner', '/kuesioner'),
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
  const _ActionData(this.icon, this.label, this.route);
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
// Gradients
// =========================
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
