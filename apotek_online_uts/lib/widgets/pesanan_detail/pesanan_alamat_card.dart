import 'package:flutter/material.dart';
import '../../models/pesanan_model.dart';

class PesananAlamatCard extends StatelessWidget {
  final PesananModel pesanan;

  const PesananAlamatCard({super.key, required this.pesanan});

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
          Row(
            children: const [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF0284C7),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Tujuan & Layanan Pengiriman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pesanan.namaPenerima,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pesanan.alamat,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_bike_outlined,
                  size: 16,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pesanan.rajaongkirService != null
                        ? 'Pengiriman: ${pesanan.rajaongkirService}'
                        : 'Kurir: ${pesanan.kurir?.nama ?? "Kurir Farmasi"} (${pesanan.kurir?.wilayah ?? "-"})',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (pesanan.nomorResep != null &&
              pesanan.nomorResep!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resep Dokter: ${pesanan.nomorResep}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
