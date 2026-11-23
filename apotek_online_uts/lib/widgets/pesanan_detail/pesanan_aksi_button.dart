import 'package:flutter/material.dart';
import '../../models/pesanan_model.dart';

class PesananAksiButton extends StatelessWidget {
  final PesananModel pesanan;
  final bool sedangUbahStatus;
  final void Function(String statusTarget, String pesanSukses) onUbahStatus;

  const PesananAksiButton({
    super.key,
    required this.pesanan,
    required this.sedangUbahStatus,
    required this.onUbahStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (pesanan.status == 'menunggu_pembayaran' &&
        pesanan.metodePembayaran != 'xendit') {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sedangUbahStatus
                ? null
                : () => onUbahStatus(
                      'menunggu_konfirmasi',
                      'Pembayaran diteruskan! Menunggu konfirmasi admin.',
                    ),
            icon: sedangUbahStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.payments_outlined, size: 18),
            label: Text(
              pesanan.metodePembayaran == 'transfer_manual'
                  ? 'Saya Sudah Transfer (Konfirmasi)'
                  : 'Bayar Pesanan (COD)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005B82),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    if (pesanan.status == 'dikirim') {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sedangUbahStatus
                ? null
                : () => onUbahStatus(
                      'selesai',
                      'Pesanan telah selesai diterima dengan baik.',
                    ),
            icon: sedangUbahStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'Pesanan Sudah Sampai (Selesai)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
