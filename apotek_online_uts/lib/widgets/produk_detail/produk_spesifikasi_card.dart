import 'package:flutter/material.dart';
import '../../models/produk_model.dart';

class ProdukSpesifikasiCard extends StatelessWidget {
  final ProdukModel produk;

  const ProdukSpesifikasiCard({super.key, required this.produk});

  Widget _buildRowDetail(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
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
            'Informasi Produk & Medis',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildRowDetail('Satuan Kemasan', produk.satuan),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _buildRowDetail('Stok Tersedia', '${produk.stok} ${produk.satuan}'),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _buildRowDetail(
            'Batas Maks. Beli',
            '${produk.batasPerPembelian} item / transaksi',
          ),
          if (produk.golongan != null && produk.golongan!.isNotEmpty) ...[
            const Divider(height: 12, color: Color(0xFFF1F5F9)),
            _buildRowDetail('Golongan Obat', produk.golongan!, isHighlight: true),
          ],
        ],
      ),
    );
  }
}
