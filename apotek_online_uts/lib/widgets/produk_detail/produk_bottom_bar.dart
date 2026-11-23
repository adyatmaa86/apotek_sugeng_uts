import 'package:flutter/material.dart';
import '../../models/produk_model.dart';

class ProdukBottomBar extends StatelessWidget {
  final ProdukModel? produk;
  final int jumlah;
  final bool sedangMenambah;
  final VoidCallback onKurang;
  final VoidCallback onTambah;
  final VoidCallback onTambahKeKeranjang;

  const ProdukBottomBar({
    super.key,
    required this.produk,
    required this.jumlah,
    required this.sedangMenambah,
    required this.onKurang,
    required this.onTambah,
    required this.onTambahKeKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    final p = produk;
    final isHabis = p == null || !p.tersedia || p.stok <= 0;

    if (isHabis) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: const Text(
          'Produk saat ini sedang habis atau tidak tersedia untuk dibeli.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stepper Kuantitas
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: const Color(0xFF334155),
                  onPressed: jumlah > 1 ? onKurang : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  alignment: Alignment.center,
                  child: Text(
                    '$jumlah',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: const Color(0xFF334155),
                  onPressed:
                      (jumlah < p.stok && jumlah < p.batasPerPembelian)
                          ? onTambah
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Tombol Tambah ke Keranjang
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: sedangMenambah ? null : onTambahKeKeranjang,
                icon: sedangMenambah
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text(
                  sedangMenambah
                      ? 'Menambahkan...'
                      : 'Tambah ke Keranjang',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005B82),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
