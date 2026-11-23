import 'package:flutter/material.dart';

import 'checkout_card_section.dart';

/// Section 4: Pilihan Metode Pembayaran (COD, Transfer Bank, Xendit).
class CheckoutPembayaranSection extends StatelessWidget {
  final String metodePembayaran;
  final ValueChanged<String> onMetodeChanged;

  const CheckoutPembayaranSection({
    super.key,
    required this.metodePembayaran,
    required this.onMetodeChanged,
  });

  Widget _buildOption({
    required String value,
    required String title,
    required String subtitle,
    bool isHighlight = false,
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
                color: dipilih
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHighlight) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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
      title: '4. Metode Pembayaran',
      subtitle: 'Pilih kanal pembayaran yang paling nyaman',
      content: Column(
        children: [
          _buildOption(
            value: 'cod',
            title: 'Bayar Tunai di Tempat (COD)',
            subtitle:
                'Pembayaran tunai langsung ke kurir saat paket obat sampai.',
          ),
          const SizedBox(height: 8),
          _buildOption(
            value: 'transfer_manual',
            title: 'Transfer Bank Manual',
            subtitle: 'Transfer rekening ke Bank Apotek Sugeng.',
          ),
          const SizedBox(height: 8),
          _buildOption(
            value: 'xendit',
            title: 'Xendit Payment Gateway (Unggulan)',
            subtitle:
                'QRIS, Virtual Account, & E-Wallet terverifikasi otomatis.',
            isHighlight: true,
          ),
        ],
      ),
    );
  }
}
