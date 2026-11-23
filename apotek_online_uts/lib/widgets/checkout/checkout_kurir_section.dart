import 'package:flutter/material.dart';

import '../../utils/format_rupiah.dart';
import 'checkout_card_section.dart';

/// Section 3: Pilihan Kurir & Tarif RajaOngkir.
class CheckoutKurirSection extends StatelessWidget {
  final Map<String, dynamic>? kotaDipilih;
  final bool isMemuatTarif;
  final List<Map<String, dynamic>> layananRajaOngkir;
  final Map<String, dynamic>? layananDipilih;
  final ValueChanged<Map<String, dynamic>> onLayananDipilih;

  const CheckoutKurirSection({
    super.key,
    required this.kotaDipilih,
    required this.isMemuatTarif,
    required this.layananRajaOngkir,
    required this.layananDipilih,
    required this.onLayananDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return CheckoutCardSection(
      icon: Icons.local_shipping_outlined,
      title: '3. Kurir & Layanan Pengiriman',
      subtitle: 'Tarif resmi terhubung API RajaOngkir JNE',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kotaDipilih == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih kota tujuan pengiriman untuk mengecek ongkir resmi.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isMemuatTarif)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Menghitung ongkos kirim JNE...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (layananRajaOngkir.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Layanan JNE belum menjangkau kota tujuan ini.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFB45309),
                ),
              ),
            )
          else
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: layananDipilih,
              decoration: buildCheckoutInputDecoration(
                hint: 'Pilih Paket Pengiriman JNE',
                prefixIcon: Icons.local_shipping_outlined,
              ),
              items: layananRajaOngkir.map((l) {
                final cost = l['cost'][0]['value'] as num;
                final etd = l['cost'][0]['etd'];
                return DropdownMenuItem(
                  value: l,
                  child: Text(
                    '${l['service']} — ${formatRupiah(cost)} ($etd hari)',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                onLayananDipilih(val);
              },
            ),
        ],
      ),
    );
  }
}
