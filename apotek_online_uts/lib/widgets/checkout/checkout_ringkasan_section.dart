import 'package:flutter/material.dart';

import '../../models/keranjang_model.dart';
import '../../utils/format_rupiah.dart';
import 'checkout_card_section.dart';

/// Section 5: Ringkasan Produk & Rincian Estimasi Biaya Tagihan.
class CheckoutRingkasanSection extends StatelessWidget {
  final KeranjangDataModel keranjangData;
  final int ongkirRajaOngkir;
  final int hitungPerkiraanTotal;

  const CheckoutRingkasanSection({
    super.key,
    required this.keranjangData,
    required this.ongkirRajaOngkir,
    required this.hitungPerkiraanTotal,
  });

  Widget _buildRowBiaya(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isGreen
                ? const Color(0xFF16A34A)
                : isBold
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
      icon: Icons.receipt_long_outlined,
      title: '5. Ringkasan Pesanan',
      subtitle: '${keranjangData.totalItem} Produk Farmasi Siap Dikirim',
      content: Column(
        children: [
          // Box Preview Item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: keranjangData.items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        color: Color(0xFF0284C7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${it.produk?.nama ?? "Obat"} (${it.jumlah} ${it.produk?.satuan ?? "pcs"})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatRupiah((it.produk?.harga ?? 0) * it.jumlah),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          _buildRowBiaya(
            'Subtotal Pesanan',
            formatRupiah(keranjangData.subtotal),
          ),
          const SizedBox(height: 6),
          _buildRowBiaya(
            'Biaya Kirim JNE',
            formatRupiah(ongkirRajaOngkir),
          ),
          const SizedBox(height: 6),
          _buildRowBiaya(
            'Biaya Layanan & Kemasan Higienis',
            'Gratis',
            isGreen: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),
          _buildRowBiaya(
            'Total Tagihan',
            formatRupiah(hitungPerkiraanTotal),
            isBold: true,
          ),
        ],
      ),
    );
  }
}
