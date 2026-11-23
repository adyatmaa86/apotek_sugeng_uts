import 'package:flutter/material.dart';

import '../checkout/checkout_card_section.dart';

/// Section 3 Checkout UTS: Metode Pembayaran simulasi lokal (COD & Transfer Manual).
class CheckoutUtsPembayaranSection extends StatelessWidget {
  final String metodePembayaran;
  final ValueChanged<String> onMetodeChanged;

  const CheckoutUtsPembayaranSection({
    super.key,
    required this.metodePembayaran,
    required this.onMetodeChanged,
  });

  Widget _buildOption({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final dipilih = metodePembayaran == value;
    return InkWell(
      onTap: () => onMetodeChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: dipilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                dipilih ? Icons.radio_button_checked : Icons.radio_button_off,
                color:
                    dipilih ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
      icon: Icons.payment_outlined,
      title: '3. Metode Pembayaran',
      subtitle: 'Simulasi transaksi apotek tanpa pihak ketiga',
      content: Column(
        children: [
          _buildOption(
            value: 'cod',
            title: 'Bayar Tunai di Tempat (COD)',
            subtitle:
                'Pembayaran tunai diserahkan langsung ke kurir apotek saat obat tiba.',
          ),
          const SizedBox(height: 8),
          _buildOption(
            value: 'transfer_manual',
            title: 'Transfer Bank Manual',
            subtitle: 'Transfer langsung ke rekening Bank Apotek Sugeng.',
          ),
        ],
      ),
    );
  }
}
