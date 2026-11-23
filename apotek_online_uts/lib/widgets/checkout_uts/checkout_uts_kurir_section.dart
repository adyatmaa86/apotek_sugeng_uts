import 'package:flutter/material.dart';

import '../../models/kurir_model.dart';
import '../../utils/format_rupiah.dart';
import '../checkout/checkout_card_section.dart';

/// Section 2 Checkout UTS: Alamat teks dan pilihan kurir internal toko.
class CheckoutUtsKurirSection extends StatelessWidget {
  final TextEditingController alamatController;
  final bool isMemuatKurir;
  final String? galatKurir;
  final VoidCallback onRetryKurir;
  final List<KurirModel> daftarKurir;
  final KurirModel? kurirDipilih;
  final ValueChanged<KurirModel> onPilihKurir;

  const CheckoutUtsKurirSection({
    super.key,
    required this.alamatController,
    required this.isMemuatKurir,
    required this.galatKurir,
    required this.onRetryKurir,
    required this.daftarKurir,
    required this.kurirDipilih,
    required this.onPilihKurir,
  });

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
      icon: Icons.location_on_outlined,
      title: '2. Alamat & Wilayah Pengiriman',
      subtitle: 'Tentukan lokasi pengantaran obat oleh kurir apotek',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Alamat & Patokan Rumah *',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: alamatController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: buildCheckoutInputDecoration(
              hint:
                  'Nama jalan, nomor rumah, RT/RW, kelurahan, dan patokan rumah...',
              prefixIcon: Icons.home_outlined,
            ),
            validator: (v) => (v == null || v.trim().length < 8)
                ? 'Alamat pengantaran minimal 8 karakter'
                : null,
          ),
          const SizedBox(height: 14),
          const Text(
            'Pilih Zona Wilayah Antar Apotek *',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          if (isMemuatKurir)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0284C7),
                ),
              ),
            )
          else if (galatKurir != null)
            GestureDetector(
              onTap: onRetryKurir,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  '$galatKurir\nKetuk untuk memuat ulang kurir.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            )
          else
            ...daftarKurir.map((kurir) {
              final dipilih = kurirDipilih?.id == kurir.id;
              return InkWell(
                onTap: () => onPilihKurir(kurir),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        dipilih ? const Color(0xFFF0F9FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dipilih
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFE2E8F0),
                      width: dipilih ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dipilih
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: dipilih
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kurir.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${kurir.wilayah} • Estimasi: ${kurir.estimasi}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(kurir.tarif),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
