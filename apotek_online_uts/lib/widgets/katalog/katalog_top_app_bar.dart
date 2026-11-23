import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

/// Top bar pada halaman Katalog: Judul, Mode UTS, Riwayat, Badge Keranjang, dan Profil.
class KatalogTopAppBar extends StatelessWidget {
  final String namaPengguna;
  final String? fotoUrl;
  final bool modeUtsAktif;
  final int jumlahItemKeranjang;
  final VoidCallback onTapModeUts;
  final VoidCallback onTapRiwayat;
  final VoidCallback onTapKeranjang;
  final VoidCallback onTapProfil;

  const KatalogTopAppBar({
    super.key,
    required this.namaPengguna,
    required this.fotoUrl,
    required this.modeUtsAktif,
    required this.jumlahItemKeranjang,
    required this.onTapModeUts,
    required this.onTapRiwayat,
    required this.onTapKeranjang,
    required this.onTapProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apotek Sugeng',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Katalog Produk',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (modeUtsAktif && AuthController.to.adminAktif)
                IconButton(
                  icon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                  tooltip: 'Kelola Produk (Mode UTS)',
                  onPressed: onTapModeUts,
                ),
              IconButton(
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF334155),
                  size: 22,
                ),
                tooltip: 'Riwayat Pesanan',
                onPressed: onTapRiwayat,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF334155),
                      size: 22,
                    ),
                    tooltip: 'Keranjang Belanja',
                    onPressed: onTapKeranjang,
                  ),
                  if (jumlahItemKeranjang > 0)
                    Positioned(
                      top: 4,
                      right: 4,
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
                          '$jumlahItemKeranjang',
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
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTapProfil,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null && fotoUrl!.isNotEmpty
                      ? NetworkImage(fotoUrl!)
                      : null,
                  child: fotoUrl == null || fotoUrl!.isEmpty
                      ? Text(
                          namaPengguna.isNotEmpty
                              ? namaPengguna.substring(0, 1).toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
