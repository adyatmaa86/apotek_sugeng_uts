import 'package:flutter/material.dart';
import '../../models/pesanan_model.dart';

class PesananXenditCard extends StatelessWidget {
  final PesananModel pesanan;
  final VoidCallback onBukaInvoice;

  const PesananXenditCard({
    super.key,
    required this.pesanan,
    required this.onBukaInvoice,
  });

  @override
  Widget build(BuildContext context) {
    if (pesanan.metodePembayaran != 'xendit' ||
        pesanan.xenditPaymentUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invoice Pembayaran Xendit Gateway',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID Invoice: ${pesanan.xenditInvoiceId ?? "-"}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
            ),
          ),
          Text(
            'Status: ${pesanan.xenditStatus ?? "PENDING"}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBukaInvoice,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buka Invoice Xendit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
