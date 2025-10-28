import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu.dart';
import 'screens/infrastruktur_screen.dart';
import 'screens/kependudukan_screen.dart';
import 'screens/pendidikan_screen.dart';
import 'screens/kesehatan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://gcqxynheshjonedcnwbp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjcXh5bmhlc2hqb25lZGNud2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MjQ3OTMsImV4cCI6MjA3NzEwMDc5M30.QaSpMK4fa5-ILOgbCg1x1et_ZmcHOwYlCZw4Jn8JlVg',
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
        title: 'Login Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const RootPage(),
        routes: {
          '/infrastruktur': (context) => const InfrastrukturScreen(),
          '/kependudukan': (context) => const KependudukanScreen(),
          '/pendidikan': (context) => const PendidikanScreen(),
          '/kesehatan': (context) => const KesehatanScreen(),
        },
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Show MainMenu when signed in, otherwise Login screen
        if (auth.isSignedIn) {
          return MainMenuPage(
            desaName: 'Desa Melayu Ilir',
            kodeWilayah: '6303052009',
            totalPenduduk: 0,
            totalKK: 0,
            isAdmin: auth.isAdmin,
          );
        }
        return const LoginScreen();
      },
    );
  }
}
