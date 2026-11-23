import 'package:flutter/material.dart';
import '../../models/produk_model.dart';

class ProdukDeskripsiCard extends StatelessWidget {
  final ProdukModel produk;

  const ProdukDeskripsiCard({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                'Deskripsi & Aturan Pakai',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                produk.deskripsi ??
                    'Belum ada deskripsi dan aturan pakai khusus untuk produk ini. Konsultasikan dengan apoteker kami jika diperlukan panduan dosis.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF0284C7),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Apotek Sugeng berlisensi SIPA & SIA. Semua produk farmasi dijamin keasliannya dan disimpan sesuai standar CDOB BPOM.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
