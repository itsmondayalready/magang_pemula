import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_service.dart';
import 'services/desa_repository.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu.dart';
import 'screens/infrastruktur_screen.dart';
import 'screens/kependudukan_screen.dart';
import 'screens/pendidikan_screen.dart';
import 'screens/kesehatan_screen.dart';
import 'screens/kebencanaan_screen.dart';
import 'screens/login_log_screen.dart';
import 'screens/metadata_screen.dart';
import 'screens/profil_desa_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (gunakan kredensial yang di-obfuscate)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Desa Cantik',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const RootPage(),
        routes: {
          '/infrastruktur': (context) => const InfrastrukturScreen(),
          '/kependudukan': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String kode = '';
            String nama = 'Desa';
            if (args is Map) {
              kode = (args['kodeWilayah'] ?? '') as String;
              nama = (args['desaName'] ?? 'Desa') as String;
            }
            return KependudukanScreen(kodeWilayah: kode, desaName: nama);
          },
          '/kesehatan': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String kode = '';
            String nama = 'Desa';
            if (args is Map) {
              kode = (args['kodeWilayah'] ?? '') as String;
              nama = (args['desaName'] ?? 'Desa') as String;
            }
            return KesehatanScreen(kodeWilayah: kode, desaName: nama);
          },
          '/pendidikan': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String nama = 'Desa';
            if (args is Map) {
              nama = (args['desaName'] ?? 'Desa') as String;
            }
            return PendidikanScreen(desaName: nama);
          },
          '/kebencanaan': (context) => const KebencanaanScreen(),
          '/log-masuk': (context) => const LoginLogScreen(),
          '/metadata': (context) => const MetadataScreen(),
          '/profil-desa': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String kode = '';
            String nama = 'Desa';
            if (args is Map) {
              kode = (args['kodeWilayah'] ?? '') as String;
              nama = (args['desaName'] ?? 'Desa') as String;
            }
            return ProfilDesaScreen(kodeWilayah: kode, desaName: nama);
          },
        },
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _repo = DesaRepository();
  String? _initialKode;
  String? _initialNama;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialDesa();
  }

  Future<void> _loadInitialDesa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kode = prefs.getString('last_desa_kode');
      final nama = prefs.getString('last_desa_name');
      if (kode != null && nama != null) {
        _initialKode = kode;
        _initialNama = nama;
      } else {
        final row = await _repo.fetchDefaultDesa();
        if (row != null) {
          final k = (row['kode_wilayah'] ?? row['kode'] ?? '') as String;
          final n = (row['nama'] ?? '') as String;
          if (k.isNotEmpty && n.isNotEmpty) {
            _initialKode = k;
            _initialNama = n;
            // Persist for next time
            try {
              await prefs.setString('last_desa_kode', k);
              await prefs.setString('last_desa_name', n);
            } catch (_) {}
          }
        }
      }
    } catch (_) {
      // fallback handled below
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isSignedIn) return const LoginScreen();
        if (_loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Fallback if nothing could be loaded
        final nama = _initialNama ?? 'Desa Melayu Ilir';
        final kode = _initialKode ?? '6303052009';
        return MainMenuPage(
          desaName: nama,
          kodeWilayah: kode,
          totalPenduduk: 0,
          totalKK: 0,
          isAdmin: auth.isAdmin,
        );
      },
    );
  }
}
