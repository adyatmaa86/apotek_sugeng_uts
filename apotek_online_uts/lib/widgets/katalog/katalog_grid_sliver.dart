import 'package:flutter/material.dart';

import '../../models/produk_model.dart';
import 'katalog_produk_card.dart';

/// SliverGrid untuk menampilkan produk dalam grid 2 kolom beserta loader pagination.
class KatalogGridSliver extends StatelessWidget {
  final List<ProdukModel> daftarProduk;
  final bool sedangMuatLebih;
  final ValueChanged<ProdukModel> onTapProduk;
  final ValueChanged<ProdukModel> onTambahKeranjang;

  const KatalogGridSliver({
    super.key,
    required this.daftarProduk,
    required this.sedangMuatLebih,
    required this.onTapProduk,
    required this.onTambahKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final produk = daftarProduk[index];
            return KatalogProdukCard(
              produk: produk,
              onTap: () => onTapProduk(produk),
              onTambahKeranjang: () => onTambahKeranjang(produk),
            );
          },
          childCount: daftarProduk.length,
        ),
      ),
    );
  }
}
