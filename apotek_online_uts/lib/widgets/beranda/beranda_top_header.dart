import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

/// Header bagian atas Beranda: Logo, Sapaan Pengguna, Mode UTS, Badge Keranjang, dan Profil.
class BerandaTopHeader extends StatelessWidget {
  final String namaPengguna;
  final String? fotoUrl;
  final bool modeUtsAktif;
  final int jumlahItemKeranjang;
  final VoidCallback onTapModeUts;
  final VoidCallback onTapKeranjang;
  final VoidCallback onTapProfil;

  const BerandaTopHeader({
    super.key,
    required this.namaPengguna,
    required this.fotoUrl,
    required this.modeUtsAktif,
    required this.jumlahItemKeranjang,
    required this.onTapModeUts,
    required this.onTapKeranjang,
    required this.onTapProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          // Logo & Sapaan
          Image.asset(
            'assets/images/logo.png',
            width: 42,
            height: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Apotek Sugeng',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                  ],
                ),
                Text(
                  'Halo, $namaPengguna 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Mode UTS Button (jika aktif & sedang login sebagai admin)
          if (modeUtsAktif && AuthController.to.adminAktif)
            IconButton(
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF0284C7),
              ),
              tooltip: 'Kelola Produk (Mode UTS)',
              onPressed: onTapModeUts,
            ),

          // Keranjang Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTapKeranjang,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF334155),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (jumlahItemKeranjang > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
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
          const SizedBox(width: 8),

          // Profile Avatar
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTapProfil,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0284C7),
              backgroundImage:
                  fotoUrl != null && fotoUrl!.isNotEmpty
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
    );
  }
}
