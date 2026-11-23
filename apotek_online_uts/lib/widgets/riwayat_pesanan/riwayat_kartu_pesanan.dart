import 'package:flutter/material.dart';

import '../../models/pesanan_model.dart';
import '../../utils/format_rupiah.dart';

/// Kartu tampilan riwayat pesanan individual.
class RiwayatKartuPesanan extends StatelessWidget {
  final PesananModel pesanan;
  final VoidCallback onLihatResep;
  final VoidCallback onDetail;
  final VoidCallback onBeliLagiAtauLacak;

  const RiwayatKartuPesanan({
    super.key,
    required this.pesanan,
    required this.onLihatResep,
    required this.onDetail,
    required this.onBeliLagiAtauLacak,
  });

  Color _getStatusColor(String status) {
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

  Color _getStatusBgColor(String status) {
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

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'MENUNGGU';
      case 'menunggu_konfirmasi':
        return 'KONFIRMASI';
      case 'diproses':
        return 'DIPROSES';
      case 'dikirim':
        return 'DIKIRIM';
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

  IconData _getMetodeIcon(String metode) {
    final m = metode.toLowerCase();
    if (m.contains('xendit')) {
      return Icons.qr_code_2_rounded;
    } else if (m.contains('cod')) {
      return Icons.local_shipping_outlined;
    } else {
      return Icons.account_balance_outlined;
    }
  }

  String _formatMetodeLabel(String metode) {
    final m = metode.toLowerCase();
    if (m.contains('xendit')) {
      return 'Xendit Gateway';
    } else if (m.contains('cod')) {
      return 'Cash on Delivery (COD)';
    } else if (m.contains('transfer')) {
      return 'Transfer Manual';
    }
    return metode.toUpperCase();
  }

  String _formatWaktu(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final jam = dt.hour.toString().padLeft(2, '0');
      final menit = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')} ${bulan[dt.month - 1]} ${dt.year}, $jam:$menit WIB';
    } catch (_) {
      // Fallback jika format tanggal tidak sesuai ISO 8601
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusWarna = _getStatusColor(pesanan.status);
    final statusBg = _getStatusBgColor(pesanan.status);
    final statusLabel = _formatStatusLabel(pesanan.status);
    final adaResep =
        pesanan.nomorResep != null && pesanan.nomorResep!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Ikon, Nomor Pesanan, Metode, dan Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getMetodeIcon(pesanan.metodePembayaran),
                    color: const Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesanan.nomorPesanan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _getMetodeIcon(pesanan.metodePembayaran),
                            size: 13,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatMetodeLabel(pesanan.metodePembayaran),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusWarna,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusWarna,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Baris 2: Rincian Produk & Waktu Transaksi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pesanan.details.length} Produk Farmasi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatRupiah(pesanan.total),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Waktu Transaksi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatWaktu(pesanan.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Catatan kurir jika pesanan dikirim
            if (pesanan.status.toLowerCase() == 'dikirim') ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.motorcycle_outlined,
                    size: 15,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Menunggu penjemputan kurir farmasi',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Baris 3: Tombol Aksi (Lihat Resep, Detail, Beli Lagi / Lacak Kurir)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (adaResep) ...[
                  OutlinedButton.icon(
                    onPressed: onLihatResep,
                    icon: const Icon(Icons.description_outlined, size: 15),
                    label: const Text(
                      'Lihat Resep',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      backgroundColor: const Color(0xFFF0F9FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.receipt_outlined, size: 15),
                  label: const Text(
                    'Detail',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onBeliLagiAtauLacak,
                  icon: Icon(
                    pesanan.status.toLowerCase() == 'dikirim' &&
                            pesanan.kurir != null
                        ? Icons.location_on_outlined
                        : Icons.replay_outlined,
                    size: 15,
                  ),
                  label: Text(
                    pesanan.status.toLowerCase() == 'dikirim' &&
                            pesanan.kurir != null
                        ? 'Lacak Kurir'
                        : 'Beli Lagi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B82),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
