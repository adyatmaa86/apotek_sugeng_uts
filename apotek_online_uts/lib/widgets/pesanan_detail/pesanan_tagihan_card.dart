import 'package:flutter/material.dart';
import '../../models/pesanan_model.dart';
import '../../utils/format_rupiah.dart';

class PesananTagihanCard extends StatelessWidget {
  final PesananModel pesanan;

  const PesananTagihanCard({super.key, required this.pesanan});

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isTotal ? 17 : 13.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Tagihan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildRow('Subtotal Produk', formatRupiah(pesanan.subtotal)),
          _buildRow('Ongkos Kirim', formatRupiah(pesanan.ongkosKirim)),
          _buildRow(
            'Metode Pembayaran',
            pesanan.metodePembayaran.toUpperCase().replaceAll('_', ' '),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildRow(
            'Total Akhir',
            formatRupiah(pesanan.total),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}
