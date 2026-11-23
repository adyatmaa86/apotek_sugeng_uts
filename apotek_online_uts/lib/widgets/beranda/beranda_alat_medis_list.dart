import 'package:flutter/material.dart';

import '../../models/produk_model.dart';
import '../../utils/format_rupiah.dart';
import '../../utils/url_berkas.dart';

/// Bagian Rekomendasi Alat Medis (Header + SliverList item).
class BerandaAlatMedisList extends StatelessWidget {
  final List<ProdukModel> produkList;
  final bool hasMore;
  final ValueChanged<ProdukModel> onTapProduk;
  final ValueChanged<ProdukModel> onTambahKeranjang;

  const BerandaAlatMedisList({
    super.key,
    required this.produkList,
    required this.hasMore,
    required this.onTapProduk,
    required this.onTambahKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                'Rekomendasi Alat Medis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Teruji Klinis',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sliver list untuk item produk alat medis vertikal.
class BerandaAlatMedisSliverList extends StatelessWidget {
  final List<ProdukModel> produkList;
  final bool hasMore;
  final ValueChanged<ProdukModel> onTapProduk;
  final ValueChanged<ProdukModel> onTambahKeranjang;

  const BerandaAlatMedisSliverList({
    super.key,
    required this.produkList,
    required this.hasMore,
    required this.onTapProduk,
    required this.onTambahKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    if (produkList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Tidak ada alat kesehatan tersedia.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == produkList.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              );
            }

            final produk = produkList[index];
            final foto = UrlBerkas.dari(produk.fotoUrl);
            final isHabis = !produk.tersedia || produk.stok <= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => onTapProduk(produk),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 76,
                          height: 76,
                          color: const Color(0xFFF1F5F9),
                          child: foto != null
                              ? Image.network(
                                  foto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.medication_outlined,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.medication_outlined,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Detail Produk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHabis
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isHabis
                                        ? 'STOK HABIS'
                                        : '${produk.kategori} • Sisa: ${produk.stok}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isHabis
                                          ? Colors.red.shade700
                                          : const Color(0xFF0369A1),
                                    ),
                                  ),
                                ),
                                if (produk.perluResep) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Resep',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Nama
                            Text(
                              produk.nama,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Deskripsi
                            Text(
                              produk.deskripsi ?? 'Satuan: ${produk.satuan}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Harga
                            Text(
                              formatRupiah(produk.harga),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol Plus (+) / Habis
                      if (isHabis)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.block,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Habis',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => onTambahKeranjang(produk),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: produkList.length + (hasMore ? 1 : 0),
        ),
      ),
    );
  }
}
