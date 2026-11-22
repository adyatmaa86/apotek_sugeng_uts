import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/keranjang_controller.dart';
import '../screens/beranda_screen.dart';
import '../screens/katalog_screen.dart';
import '../screens/keranjang_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/riwayat_pesanan_screen.dart';

/// Navigation Bar bawah terpusat (GetX Reactive).
/// Menggunakan [KeranjangController] untuk badge kuantitas keranjang secara otomatis.
class NavBarBawah extends StatelessWidget {
  final int currentIndex;

  const NavBarBawah({
    super.key,
    required this.currentIndex,
  });

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const BerandaScreen();
        break;
      case 1:
        target = const KatalogScreen();
        break;
      case 2:
        target = const KeranjangScreen();
        break;
      case 3:
        target = const RiwayatPesananScreen();
        break;
      case 4:
        target = const ProfilScreen();
        break;
      default:
        return;
    }

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => target),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan KeranjangController tersedia
    final keranjangCtrl = Get.isRegistered<KeranjangController>()
        ? KeranjangController.to
        : Get.put(KeranjangController());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => _onDestinationSelected(context, idx),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F2FE),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0284C7)),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF0284C7)),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Obx(() {
              final count = keranjangCtrl.totalItem;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF64748B),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0284C7),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            selectedIcon: const Icon(
              Icons.shopping_bag,
              color: Color(0xFF0284C7),
            ),
            label: 'Keranjang',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF0284C7)),
            label: 'Riwayat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0284C7)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
