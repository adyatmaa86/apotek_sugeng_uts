import 'package:flutter/material.dart';

import '../../models/produk_model.dart';
import '../../utils/format_rupiah.dart';
import '../../utils/url_berkas.dart';

/// Kartu produk dalam grid katalog.
class KatalogProdukCard extends StatelessWidget {
  final ProdukModel produk;
  final VoidCallback onTap;
  final VoidCallback onTambahKeranjang;

  const KatalogProdukCard({
    super.key,
    required this.produk,
    required this.onTap,
    required this.onTambahKeranjang,
  });

  @override
  Widget build(BuildContext context) {
    final isHabis = !produk.tersedia || produk.stok <= 0;
    final fotoUrl = UrlBerkas.dari(produk.fotoUrl);

    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk + Badge Resep / Kategori
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: isHabis
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFE0F2FE),
                    child: fotoUrl != null && fotoUrl.isNotEmpty
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              produk.kategori == 'Obat'
                                  ? Icons.medication_liquid_outlined
                                  : Icons.medical_services_outlined,
                              size: 40,
                              color: isHabis
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0284C7),
                            ),
                          )
                        : Icon(
                            produk.kategori == 'Obat'
                                ? Icons.medication_liquid_outlined
                                : Icons.medical_services_outlined,
                            size: 40,
                            color: isHabis
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0284C7),
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
                      color: Colors.white.withValues(alpha: 0.92),
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

            // Detail Informasi Produk
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
                      color: isHabis ? Colors.red : const Color(0xFF64748B),
                      fontWeight:
                          isHabis ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    produk.nama,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatRupiah(produk.harga),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            Text(
                              '/${produk.satuan}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: isHabis ? null : onTambahKeranjang,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isHabis
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              color: isHabis
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              size: 18,
                            ),
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
  }
}
