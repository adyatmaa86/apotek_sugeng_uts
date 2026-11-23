import 'package:flutter/material.dart';

import '../../models/produk_model.dart';
import '../../utils/format_rupiah.dart';
import '../../utils/url_berkas.dart';

/// Daftar horizontal produk terlaris dengan kartu ringkas.
class BerandaProdukTerlaris extends StatelessWidget {
  final List<ProdukModel> daftarProduk;
  final ValueChanged<ProdukModel> onTapProduk;
  final ValueChanged<ProdukModel> onTambahKeranjang;

  const BerandaProdukTerlaris({
    super.key,
    required this.daftarProduk,
    required this.onTapProduk,
    required this.onTambahKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                'Produk Terlaris',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Top Penjualan',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 236,
          child: daftarProduk.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada produk tersedia',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: daftarProduk.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final produk = daftarProduk[index];
                    final foto = UrlBerkas.dari(produk.fotoUrl);
                    final isHabis = !produk.tersedia || produk.stok <= 0;

                    return GestureDetector(
                      onTap: () => onTapProduk(produk),
                      child: Container(
                        width: 158,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto & Label
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: SizedBox(
                                    height: 110,
                                    width: double.infinity,
                                    child: foto != null
                                        ? Image.network(
                                            foto,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: const Color(0xFFF1F5F9),
                                              child: const Icon(
                                                Icons.medication_outlined,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(
                                              Icons.medication_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      produk.kategori,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                                if (produk.perluResep)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Resep',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHabis
                                        ? 'Stok Habis'
                                        : 'Stok: ${produk.stok} ${produk.satuan}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isHabis
                                          ? Colors.red
                                          : const Color(0xFF64748B),
                                      fontWeight: isHabis
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    produk.nama,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          formatRupiah(produk.harga),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: isHabis
                                            ? null
                                            : () => onTambahKeranjang(produk),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: isHabis
                                                ? const Color(0xFFE2E8F0)
                                                : const Color(0xFF38BDF8),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: isHabis
                                                ? Colors.grey
                                                : Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
