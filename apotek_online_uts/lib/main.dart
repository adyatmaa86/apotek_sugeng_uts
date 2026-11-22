import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/keranjang_controller.dart';
import 'screens/beranda_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authController = Get.put(AuthController());
  await authController.muat();
  Get.put(KeranjangController());

  runApp(const ApotekOnlineApp());
}

class ApotekOnlineApp extends StatelessWidget {
  const ApotekOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Apotek Sugeng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      ),
      home: const BerandaScreen(),
    );
  }
}
