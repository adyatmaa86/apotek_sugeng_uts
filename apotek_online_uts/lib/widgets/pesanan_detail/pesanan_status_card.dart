import 'package:flutter/material.dart';
import '../../models/pesanan_model.dart';

class PesananStatusCard extends StatelessWidget {
  final PesananModel pesanan;

  const PesananStatusCard({super.key, required this.pesanan});

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF16A34A);
      case 'dibayar':
      case 'diproses':
        return const Color(0xFF0284C7);
      case 'dikirim':
        return const Color(0xFF4F46E5);
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
        return const Color(0xFFD97706);
      case 'dibatalkan':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFFDCFCE7);
      case 'dibayar':
      case 'diproses':
        return const Color(0xFFE0F2FE);
      case 'dikirim':
        return const Color(0xFFEEF2FF);
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
        return const Color(0xFFFEF3C7);
      case 'dibatalkan':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static String formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'MENUNGGU PEMBAYARAN';
      case 'menunggu_konfirmasi':
        return 'MENUNGGU KONFIRMASI';
      case 'diproses':
        return 'DIPROSES';
      case 'dikirim':
        return 'SEDANG DIKIRIM';
      case 'dibayar':
        return 'DIBAYAR';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nomor Pesanan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pesanan.nomorPesanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: getStatusBgColor(pesanan.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: getStatusColor(pesanan.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formatStatusLabel(pesanan.status),
                      style: TextStyle(
                        color: getStatusColor(pesanan.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Waktu Pemesanan: ${pesanan.createdAt}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
