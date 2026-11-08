import 'package:flutter/material.dart';

import 'screens/katalog_screen.dart';
import 'utils/app_state.dart';
import 'services/layanan_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat sesi login tersimpan (token Sanctum + profil) sebelum aplikasi jalan.
  await SesiAuth.muat();
  LayananApi.setToken(SesiAuth.token);

  runApp(const ApotekOnlineApp());
}

class ApotekOnlineApp extends StatelessWidget {
  const ApotekOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apotek Sehat Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      ),
      home: const KatalogScreen(),
    );
  }
}
