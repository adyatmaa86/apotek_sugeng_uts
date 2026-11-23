import 'package:flutter/material.dart';
import '../../models/produk_model.dart';
import '../../utils/format_rupiah.dart';
import '../../utils/url_berkas.dart';

class KelolaProdukCard extends StatelessWidget {
  final ProdukModel produk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KelolaProdukCard({
    super.key,
    required this.produk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = produk;
    final bool isStokKosong = p.stok <= 0;
    final bool isTidakTersedia = !p.tersedia;
    final bool isDisabled = isStokKosong || isTidakTersedia;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDisabled ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto / Icon Produk
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.shade200
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: () {
                    final fotoUrl = UrlBerkas.dari(p.fotoUrl);
                    return fotoUrl != null && fotoUrl.isNotEmpty
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              p.kategori == 'Obat'
                                  ? Icons.medication_liquid_outlined
                                  : Icons.medical_services_outlined,
                              color: isDisabled
                                  ? Colors.grey
                                  : const Color(0xFF0284C7),
                              size: 28,
                            ),
                          )
                        : Icon(
                            p.kategori == 'Obat'
                                ? Icons.medication_liquid_outlined
                                : Icons.medical_services_outlined,
                            color: isDisabled
                                ? Colors.grey
                                : const Color(0xFF0284C7),
                            size: 28,
                          );
                  }(),
                ),
                const SizedBox(width: 12),

                // Detail Nama & Harga
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nama,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDisabled
                              ? Colors.grey.shade700
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatRupiah(p.harga)} / ${p.satuan}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? Colors.grey
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Aksi Ubah & Hapus
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                      ),
                      tooltip: 'Ubah Produk',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      tooltip: 'Hapus Produk',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Penanda Status Jelas (Stok Nol / Tidak Tersedia / Resep)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (isStokKosong)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.shade400,
                      ),
                    ),
                    child: const Text(
                      '⛔ Stok Habis (0)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      'Stok: ${p.stok}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),

                if (isTidakTersedia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.shade400,
                      ),
                    ),
                    child: const Text(
                      '⚠️ Tidak Tersedia',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),

                if (p.perluResep)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.shade300,
                      ),
                    ),
                    child: const Text(
                      'Wajib Resep Dokter',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Max Beli: ${p.batasPerPembelian}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
