import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/url_berkas.dart';

/// Header bagian atas pada halaman Riwayat Pesanan.
class RiwayatTopHeader extends StatelessWidget {
  final VoidCallback onTapNotifikasi;
  final VoidCallback onTapProfil;

  const RiwayatTopHeader({
    super.key,
    required this.onTapNotifikasi,
    required this.onTapProfil,
  });

  @override
  Widget build(BuildContext context) {
    final namaPengguna =
        AuthController.to.pengguna.value?.nama ?? 'Tamu (Guest)';
    final fotoUrl = UrlBerkas.dari(AuthController.to.pengguna.value?.fotoUrl);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                'Riwayat Pesanan',
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
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF334155),
                  size: 24,
                ),
                onPressed: onTapNotifikasi,
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTapProfil,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7),
                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null || fotoUrl.isEmpty
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
