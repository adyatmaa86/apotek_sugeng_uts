import 'package:flutter/material.dart';

import '../../models/keranjang_model.dart';
import '../../utils/format_rupiah.dart';
import '../../utils/url_berkas.dart';

/// Kartu item keranjang individual dengan stepper counter dan aksi hapus.
class KartuItemKeranjang extends StatelessWidget {
  final ItemKeranjangModel item;
  final void Function(ItemKeranjangModel item, int delta) onUbahJumlah;
  final void Function(ItemKeranjangModel item) onHapus;

  const KartuItemKeranjang({
    super.key,
    required this.item,
    required this.onUbahJumlah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final produk = item.produk;
    final fotoUrl = UrlBerkas.dari(produk?.fotoUrl);
    final hargaItem = produk?.harga ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Produk
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFF1F5F9),
                  child: fotoUrl != null && fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
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

              // Detail & Harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk?.nama ?? 'Produk #${item.produkId}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        produk?.kategori ?? 'Obat',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Harga Satuan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      formatRupiah(hargaItem),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Stepper Counter Jumlah & Tombol Hapus
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onUbahJumlah(item, -1),
                          child: const SizedBox(
                            width: 28,
                            height: 32,
                            child: Center(
                              child: Icon(
                                Icons.remove,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${item.jumlah}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onUbahJumlah(item, 1),
                          child: Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onHapus(item),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Indikator Stok & Label Resep
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 13,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              Text(
                'Stok tersedia: ${produk?.stok ?? "-"} ${produk?.satuan ?? "pcs"}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (produk?.perluResep == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Wajib Resep',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
